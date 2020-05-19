import 'dart:convert';

import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';

import 'package:sync_layer/types/object_reference.dart';
import 'abstract/index.dart';

/// Meta fixed key numbers!
const _TOMBSTONE = '__tombstone';
const _TOMBSTONE_NUM = 0xff as Object;

/// TODO:
/// * Think about Tombstone
/// * Think about Meta data
/// * revert option
/// * change List to Map!
/// * add stream listener
///
///
///
class _Entry {
  _Entry(this.id, this.value);
  final IdBase id;
  final dynamic value;

  @override
  String toString() => 'Entry(c: $id, v: $value)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is _Entry && o.id == id && o.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}

/// Specify the [Key] as [String] or [int] or dynamic to use both types of key
/// number and strings
class SyncableObjectImpl<Key, Type extends SyncableObject> implements SyncableObject<Key> {
  /// **Important**
  ///
  /// if Id is not provided,  the container function generateID gets called!
  /// this function is provided by the sync layer, therefore the synclayer
  /// deceides which the form of the id

  SyncableObjectImpl(String id, this._accessor, {this.notify})
      : assert(_accessor != null, 'Accessor prop cannot be null'),
        _id = id ?? _accessor.generateID() {
    /// direct set! no Id/Ts
    // if (Key is int) if (Key is String) ;

    _internal[_TOMBSTONE_NUM] = _Entry(null, false);
  }

  // @override
  // Accessor get accessor => _accessor;
  final AcessProxy _accessor;

  Function(Key key, _Entry entry) notify;

  /// Stores the key /values of the keys, specify by the user.
  /// in case of a synable object, it stores the type and id
  final Map<Key, _Entry> _internal = {};

  /// Stores the reference to the syncable Object, once it gets called, not present if not called
  /// => lazy
  final Map<Key, SyncableObject> _syncableObjectsRefs = {};

  /// Getter Setter

  @override
  int get type => _accessor.type;

  @override
  String get id => _id;
  final String _id;

  /// Marks if the object is deleted!
  @override
  bool get tombstone => _getValue(_TOMBSTONE_NUM);

  @override
  set tombstone(bool v) => _setValue(_TOMBSTONE_NUM, v);

  /// Internal get and setter
  @pragma('vm:prefer-inline')
  SyncableObject _getSyncableObjectRef(Key key) => _syncableObjectsRefs[key];

  @pragma('vm:prefer-inline')
  void _setSyncableObjectRef(Key key, SyncableObject obj) => _syncableObjectsRefs[key] = obj;

  @pragma('vm:prefer-inline')
  dynamic _getValue(Key key) => _internal[key]?.value;

  /// gets the Id base as timestamp and site id
  @pragma('vm:prefer-inline')
  IdBase _getIdTs(Key key) => _internal[key]?.id;

  /// set value should only be used by apply atom,
  /// since this sets the _internal object with the object entry
  @pragma('vm:prefer-inline')
  void __setInternalValue(Key key, _Entry entry) {
    _internal[key] = entry;

    if (notify != null) notify(key, entry);
  }

  /// once a key gets set, this will send the update action via
  /// [container.update]. This will create an Atom and sends it back to
  /// apply to the [_internal] through the synclayer
  ///
  /// THINK: maybe a short cut could be created?
  ///
  bool _subTransaction = false;
  final _subTransactionMap = <Key, dynamic>{};

  /// With subtransaction, assigning multiple values to the object,
  /// no update is triggered until function is finished
  /// then all changes as send in one Atom
  ///
  /// *Note: Changes are stored in a Map, therefor, appling the same Key, will result in the
  /// last writer wins
  @override
  void transact(void Function(Type ref) func) {
    // start changes
    _subTransaction = true;
    func(this as Type);
    // Stop changes
    _subTransaction = false;
    // send atom

    final copy = {..._subTransactionMap};
    final atom = _accessor.update(id, copy);
    // creates new map for next
    _subTransactionMap.clear();
  }

  void _setValue(Key key, dynamic value) {
    /// check if value is [SyncableObject] and if so create Ref to object of type
    if (value is SyncableObject) {
      value = ObjectReference(value.type, value.id);
    }

    if (_subTransaction) {
      _subTransactionMap[key] = value;
    } else {
      final atom = _accessor.update(id, {key: value});
    }

    /// Todo: set atom entry now?....
  }

  @override
  IdBase getFieldOriginId(Key key) => _getIdTs(key);

  /// TODO: what should we do?
  @override
  List<AtomBase> get history => _history.toList()..sort();
  final Set<AtomBase> _history = {};

  /// Returns the timestamp for that key
  @override
  IdBase get lastUpdated => _lastUpdated;
  IdBase _lastUpdated;

  /// looks up first if something is in synable object else in the
  /// regular object by this key
  @override
  dynamic operator [](Key key) => _getSyncableObjectRef(key) ?? _getValue(key);

  /// sets the value, send [FIRST] to sync layer, create atom, and then apply
  @override
  operator []=(Key key, dynamic value) => _setValue(key, value);

  /// applies atom and returns
  ///
  ///! * implementation changed: .... below is wrong !
  ///
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  /// if -1 it throws an error
  ///
  /// TODO: should case of Atom beeing 'null' be handeled?
  /// TODO: Think, what should happen, if atom exist here?
  ///
  /// normally Synclayer is filtering it out!
  @override
  int applyAtom(AtomBase atom) {
    /// use
    // the same atom should not happen, this will only happen, if
    // the atom is not filtered out

    // if key was not set or the local time happend before [hb] to new Atom

    var ret = 0;
    for (final e in (atom.data as Map).entries) {
      final originId = _getIdTs(e.key);

      if (originId == null || (originId < atom.id)) {
        _applyUpdate(atom);
        ret = 2;
      }

      if (originId == atom.id && ret < 1) ret = 1;
    }

    /// TODO: what todo with history
    final isSet = _history.add(atom);

    logger.debug('Appy Atom needs a revisit!');
    // if keyClock > atom.clock
    return ret;
  }

  void _applyUpdate(AtomBase atom) {
    // update the lastUpdated key
    if (_lastUpdated == null || _lastUpdated < atom.id) {
      _lastUpdated = atom.id;
    }

    /// data is only two long
    for (final e in (atom.data as Map).entries) {
      final key = e.key as Key;
      final value = e.value;

      __setInternalValue(key, _Entry(atom.id, value));

      // lookup if it is on object reference
      if (value is ObjectReference) {
        final obj = _accessor.objectLookup(value);
        _setSyncableObjectRef(key, obj);
      }
    }
  }

  /// lexographical sort by Object ID
  @override
  int compareTo(SyncableObject other) {
    for (var i = 0; i < id.length; i++) {
      final lc = id.codeUnitAt(i);
      final oc = other.id.codeUnitAt(i);
      final res = lc.compareTo(oc);
      if (res != 0) return res;
    }

    return 0;
  }

  /// TODO: compare by lastUpdated

  @override
  String toString() {
    final obj = <String, dynamic>{};
    final encoder = JsonEncoder.withIndent('  ');

    for (final key in _internal.keys) {
      final c = _internal[key].id?.toString();
      var v = _internal[key].value;

      final res = {'v': v, 'c': '$c'};
      obj['$key'] = res;
    }

    final res = encoder.convert({'id': id, 'type': type, 'obj': obj.toString()});

    return res;
  }
}

// dynamic convert2Json(dynamic m) {
//   final mm = <String, dynamic>{};

//   if (m is Map) {
//     for (var e in m.entries) {
//       var value = e.value;
//       if (e.value is Map) value = convert2Json(value);
//       if (m is Set) value = e.value.toList();
//       mm['${e.key}'] = value;
//     }
//   } else if (m is Set) {
//     return m.toList();
//   } else {
//     return m;
//   }

//   return mm;
// }
