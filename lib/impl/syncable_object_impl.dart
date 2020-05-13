import 'dart:convert';

import 'package:sync_layer/crdts/values.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/abstract/index.dart';

const String _TOMBSTONE = '_tombstone_';
const String _TYPE_ID = '_type_';
const String _OBJ_ID = '_#_';

class SyncableObjectImpl implements SyncableObject {
  /// **Important**
  ///
  /// if Id is not provided,  the container function generateID gets called!
  /// this function is provided by the sync layer, therefore the synclayer
  /// deceides which the form of the id

  SyncableObjectImpl(String id, Accessor accessor)
      : _accessor = accessor,
        assert(accessor != null, 'Accessor prop cannot be null'),
        _id = id ?? accessor.generateID() {
    // define and set tombstone to false;
    _obj[_TOMBSTONE] = false;
  }
  final Accessor _accessor;

  @override
  String get type => _accessor.type;

  @override
  String get id => _id;
  final String _id;

  /// Marks if the object is deleted!
  @override
  bool get tombstone => this[_TOMBSTONE];

  @override
  set tombstone(bool v) => this[_TOMBSTONE] = v;

  /// Stores the key /values of the fields, specify by the user.
  /// in case of a synable object, it stores the type and id
  final Map<String, dynamic> _obj = {};
  final Map<String, Hlc> _objClock = {};

  /// Stores the reference to the syncable Object
  final Map<String, SyncableObject> _syncableObjects = {};

  /// Returns the timestamp for that field
  @override
  Hlc getFieldClock(String field) => _objClock[field];

  /// TODO: could be set with [applyAtoms]
  @override
  Hlc get lastUpdated {
    if (_objClock.isNotEmpty) return _objClock.values?.reduce((a, b) => a > b ? a : b);
    return null;
  }

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  /// if -1 it throws an error
  ///
  /// TODO: should case of Atom beeing 'null' be handeled?
  /// TODO: Think, what should happen, if atom exist here?
  /// normally Synclayer is filtering it out!
  @override
  int applyAtom(Atom atom) {
    final fieldClock = getFieldClock(atom.data.key);

    _history.add(atom);
    // if field was not set or the local time happend before [hb] to new Atom
    if (fieldClock == null || fieldClock < atom.clock) {
      _setField(atom);
      return 2;
    }

    if (fieldClock == atom.clock) return 1;

    // if (fieldClock > atom.clock)
    return 0;
  }

  /// somewhat redundent ?
  /// should be sorted?
  @override
  List<Atom> get history => _history.toList()..sort();
  final Set<Atom> _history = {};

  void _setField(Atom atom) {
    _obj[atom.data.key] = atom.data.value;
    _objClock[atom.data.key] = atom.clock;

    if (atom.data.value is Map) {
      final m = atom.data.value as Map;

      final String type = m[_TYPE_ID];
      final String objId = m[_OBJ_ID];

      // if it is a synable object look it up and store it in the [_syncableObjects]
      if (type != null && objId != null) {
        _syncableObjects[atom.data.key] = _accessor.objectLookup(type, objId);
      }
    }
  }

  /// looks up first if something is in synable object else in the
  /// regular object by this key
  @override
  dynamic operator [](key) {
    return _syncableObjects[key] ?? _obj[key];
  }

  /// sets the values
  @override
  operator []=(field, value) => _sendToSyncLayer(field, value);

  /// once a field gets set, this will send the update action via
  /// [container.update]. This will create an Atom and sends it back to
  /// apply to the [_obj] through the synclayer
  ///
  /// THINK: maybe a short cut could be created?
  void _sendToSyncLayer(String field, value) {
    var val = value;

    // check if value is [SyncableObject]
    if (value is SyncableObject) {
      // create Ref type
      /// TODO syncable Ref Object??
      val = {_TYPE_ID: value.type, _OBJ_ID: value.id};
    }

    _accessor.onUpdate([Value(type, id, field, val)]);
  }

  /// lexographical sort by ID
  @override
  int compareTo(SyncableObject other) {
    for (var i = 0; i < id.length; i++) {
      final lc = id.codeUnitAt(i);
      final oc = other.id.codeUnitAt(i);

      if (lc > oc) return 1;
      if (lc < oc) return -1;
    }

    return 0;
  }

  @override
  String toString() {
    final obj = {};
    for (final key in _obj.keys) {
      obj[key] = {
        'v': _obj[key],
        'c': _objClock[key]?.toStringHuman(),
      };
    }

    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(obj);
    // return obj.toString();
  }
}
