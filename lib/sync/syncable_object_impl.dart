import 'dart:async';
import 'dart:convert';

import 'package:sync_layer/basic/observable.dart';
import 'package:sync_layer/logger/logger.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';

import 'package:sync_layer/types/object_reference.dart';
import 'abstract/index.dart';
import 'abstract/syncable_base.dart';

/// Meta fixed key numbers!
const _TOMBSTONE = '__tombstone';
const _TOMBSTONE_NUM = 0xff as Object;

// TODO: create time!
class COMMON_EVENTS {
  static String DELETE = 'DELETE';
}

class IdValuePair {
  IdValuePair(this.id, this.value);
  final IdBase id;
  final dynamic value;

  @override
  String toString() => 'Entry(c: $id, v: $value)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is IdValuePair && o.id == id && o.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}

/// TODO:
/// * Think about Tombstone
/// * Think about Meta data
/// * revert option
/// * change List to Map!
/// * add stream listener
///
///
///

/// Specify the [Key] as [String] or [int] or dynamic to use both types of key
/// number and strings
///
/// [THIS] should extends from [SyncableMap]!
///
/// The Observable API is a quick and dirty hack to just listen to the delete method.
/// and will be refactored some time later!
class SyncableMap<Key, THIS extends SyncableObject> extends SyncableObject<Key> {
  /// **Important**
  ///
  /// if Id is not provided,  the container function generateID gets called!
  /// this function is provided by the sync layer, therefore the synclayer
  /// deceides which the form of the id

  SyncableMap(this._proxy, String _id)
      : assert(_proxy != null, 'AccessProxy prop cannot be null'),
        id = _id ?? _proxy.generateID() {
    _internal[_TOMBSTONE_NUM] = IdValuePair(null, false);
  }

  // fires when the object got updated!
  final _onChangeController = StreamController<bool>.broadcast();

  /// notifies, when object changes:
  @override
  Stream<bool> get onChange => _onChangeController.stream;

  StreamController get onChangeCtrl => _onChangeController;

  @override
  AccessProxy get proxy => _proxy;
  final AccessProxy _proxy;

  /// Stores the key /values of the keys, specify by the user.
  /// in case of a synable object, it stores the type and id
  final Map<Key, IdValuePair> _internal = {};

  /// Stores the reference to the syncable Object, once it gets called,
  /// not present if not called => lazy
  final Map<Key, SyncableBase> _syncableObjectsRefs = {};

  /// once a key gets set, this will send the update action via
  /// [container.mutate]. This will create an Atom and sends it back to
  /// apply to the [_internal] through the synclayer
  ///
  /// THINK: maybe a short cut could be created?
  ///
  bool _subTransaction = false;
  final _subTransactionMap = <Key, dynamic>{};

  // --------------------------------------------------------------------------->
  /// Getter Setter

  @override
  int get type => _proxy.type;

  @override
  final String id;

  /// Marks if the object is deleted!
  @override
  bool get tombstone => _getValue(_TOMBSTONE_NUM);

  @override
  void delete() {
    _setValue(_TOMBSTONE_NUM, true);
    _onChangeController.close();

    notify(COMMON_EVENTS.DELETE, true);
  }

  /// History contains all received atoms.. usefull for a standalone obj,
  /// in combination with the sync layer, which filters allready existing
  /// atoms this is not needed anymore, since it does the same job
  @override
  List<AtomBase> get history => _history.toList(growable: false)..sort();
  final Set<AtomBase> _history = {};

  /// Returns the timestamp for that key
  @override
  IdBase get lastUpdated => _lastUpdated;
  IdBase _lastUpdated;

  /// Internal get and setter
  @pragma('vm:prefer-inline')
  SyncableBase _getSyncableObjectRef(Key key) => _syncableObjectsRefs[key];

  @pragma('vm:prefer-inline')
  void _setSyncableObjectRef(Key key, SyncableBase obj) => _syncableObjectsRefs[key] = obj;

  @pragma('vm:prefer-inline')
  dynamic _getValue(Key key) => _internal[key]?.value;

  /// gets the Id base as timestamp and site id
  @pragma('vm:prefer-inline')
  IdBase _getIdTs(Key key) => _internal[key]?.id;

  @override
  IdBase getOriginIdOfKey(Key key) => _getIdTs(key);

  /// sets the value
  ///
  /// if [_subTransaction] is activated, then all changes are stored todo
  /// [_subTransactionMap] else change is applied immediately
  ///
  /// todo: Change null not supported
  void _setValue(Key key, dynamic value) {
    /// check if value is [SyncableObject] and if so create Ref to object of type
    if (value is SyncableBase) {
      value = (value as SyncableBase).toObjectRef();
    }

    if (_subTransaction) {
      _subTransactionMap[key] = value;
    } else {
      _updateLocally({key: value});
    }
  }

  /// This method will set the key and value to the internal object
  /// and will trigger the [StreamController]
  @pragma('vm:prefer-inline')
  void __setKeyValueInternal(IdBase id, Key key, dynamic value) {
    final pair = IdValuePair(id, value);
    _internal[key] = pair;

    // lookup if it is on object reference
    if (value is SyncableObjectRef) {
      final obj = _proxy.refLookup(value);
      _setSyncableObjectRef(key, obj);
    }
  }

  // ---------------------------------------------------------------------------

  /// class this function, whenever a change locally should happen:
  /// * this creates an atom => needs a timestamp
  /// * sends it to the synclayer for [localAtoms]
  /// * then applies all changes in the [data]
  /// * then notifies the Stream, that object changed
  ///
  /// TODO: Think, should a time/id comparing happening!
  void _updateLocally(Map<Key, dynamic> data) {
    final atom = _proxy.mutate(id, data);
    // set updated time
    _lastUpdated = atom.id;
    // add to local history
    _history.add(atom);

    for (var e in data.entries) {
      __setKeyValueInternal(atom.id, e.key, e.value);
    }

    if (!(tombstone == true && _onChangeController.isClosed)) {
      _onChangeController.add(true);
    }
  }

  // ---------------------------------------------------------------------------
  // Public APIs
  // ---------------------------------------------------------------------------

  /// ### Transact
  ///
  /// With [transact], assigning multiple values to [this] object,
  /// no update is triggered until function is finished
  /// then all changes are send as one Atom
  ///
  /// *Note: Changes are stored in a Map, therefor, appling the same Key,
  /// will result in the last writer wins strategy
  @override
  void transact(void Function(THIS self) func) {
    // start changes
    _subTransaction = true;
    func(this as THIS);
    _subTransaction = false;

    // copies the map and sends it
    _updateLocally({..._subTransactionMap});

    // clears map for next update
    _subTransactionMap.clear();
  }

  // ---------------------------------------------------------------------------

  //  Operator for Set Value and get Value
  /// looks up first if something is in synable object else in the
  /// regular object by this key
  @override
  dynamic operator [](Key key) => _getSyncableObjectRef(key) ?? _getValue(key);

  /// sets the value, send [FIRST] to sync layer, create atom, and then apply
  @override
  operator []=(Key key, dynamic value) => _setValue(key, value);

  // ---------------------------------------------------------------------------
  /// ### Apply remote Atom
  /// * TODO fix Me:
  /// * got [isLocalUpdate]
  ///
  ///! * implementation changed: .... below is wrong !
  ///
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => atom was allready added
  /// * returns [-2] : if nothing applied => atom was null
  /// this should nevel happen, since synclayer filteres
  ///
  ///
  /// TODO: should case of Atom beeing 'null' be handeled?
  ///
  /// normally Synclayer is filtering it out!
  /// if key was not set or the local time happend before [hb] to new Atom
  @override
  int applyRemoteAtom(AtomBase atom) {
    if (atom == null) return -2;

    if (_history.add(atom)) {
      // update the lastUpdated key
      if (_lastUpdated == null || _lastUpdated < atom.id) {
        _lastUpdated = atom.id;
      }

      var result = 0;

      final data = (atom.data as Map).cast<Key, dynamic>();

      /// test each map entry if the update should apply for that field
      for (final e in data.entries) {
        final originId = _getIdTs(e.key);

        // update only if originId/Timestamp < then current atom
        if (originId == null || (originId < atom.id)) {
          __setKeyValueInternal(atom.id, e.key, e.value);

          result = 2;
        }

        if (originId == atom.id && result < 1) result = 1;
      }

      /// update, when value changed
      if (result > 1) _onChangeController.add(null);

      return result;
    } else {
      logger.debug('Atom already received $atom');
      return -1;
      // throw AssertionError('received the same atom twice!'
      // ' todo: fix issue and remove this assertion');
    }
  }

  // ---------------------------------------------------------------------------
  // Utility function
  // ---------------------------------------------------------------------------

  /// lexographical sort by Object ID
  @override
  int compareTo(SyncableBase other) {
    for (var i = 0; i < id.length; i++) {
      final lc = id.codeUnitAt(i);
      final oc = other.id.codeUnitAt(i);
      final res = lc.compareTo(oc);
      if (res != 0) return res;
    }

    return 0;
  }

  /// TODO: compare by lastUpdated
  ///
  /// TO string will return the internal values and only object reference
  /// to prefent circlue to string calls!!!
  @override
  String toString() {
    final obj = <String, dynamic>{};
    final encoder = JsonEncoder.withIndent('  ');

    for (final key in _internal.keys) {
      final c = _internal[key].id?.toString();
      var v = _internal[key].value;

      if (v is SyncableObjectRef) {
        v = v.toString();
      } else if (v is Set) {
        v = v.toString();
      } else if (v is Map) {
        v = _toJsonMap(v);
      }

      final res = {'id': '$c', 'value': v};
      obj['$key'] = res;
    }

    final res = encoder.convert({'key-value': obj});

    return 'SyncableObjectImpl(id: "$id", type: "$type", $res';
  }
}

Map<String, dynamic> _toJsonMap(Map m) {
  final newMap = m.map((k, v) {
    var value = v is Map ? _toJsonMap(v) : v;
    value = v is Set ? v.toList() : value;

    return MapEntry(k.toString(), value);
  });

  return newMap;
}
