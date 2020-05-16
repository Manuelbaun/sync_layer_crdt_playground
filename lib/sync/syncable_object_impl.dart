import 'dart:convert';

import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/index.dart';

import 'abstract/index.dart';

const String _TOMBSTONE = '_tombstone_';

class ObjectEntry<T> {
  ObjectEntry(this.site, this.ts, this.data);
  final int site;
  final LogicalClockBase ts;
  final T data;
}

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
    _internalObject[_TOMBSTONE] = false;
  }
  final Accessor _accessor;

  @override
  int get type => _accessor.type;

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
  final Map<String, dynamic> _internalObject = {};
  final Map<String, Id> _objFieldOriginIds = {};

  // var keyCounter = 0;
  // final Map<String, int> keyNumMap = {};
  // final List<dynamic> _obj_ = [];
  // final List<Hlc> _objClock_ = [];

  // int registerField(String field) {
  //   return keyNumMap[field] = keyCounter++;
  // }

  /// Stores the reference to the syncable Object
  final Map<String, SyncableObject> _syncableObjects = {};

  /// Returns the timestamp for that field
  @override
  Id getFieldOriginId(String field) => _objFieldOriginIds[field];

  /// TODO: could be set with [applyAtoms]
  @override
  LogicalClockBase get lastUpdated {
    if (_objFieldOriginIds.isNotEmpty) return _objFieldOriginIds.values.reduce((a, b) => a.ts > b.ts ? a : b).ts;
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
  ///
  /// normally Synclayer is filtering it out!
  @override
  int applyAtom(AtomBase atom) {
    final originId = getFieldOriginId(atom.data.key);

    /// what todo with history
    _history.add(atom);

    // if field was not set or the local time happend before [hb] to new Atom
    if (originId == null || (originId < atom.id)) {
      _setField(atom);
      return 2;
    }

    // the same atom should not happen, this will only happen, if
    // the atom is not filtered out
    if (originId == atom.id) return 1;

    // if fieldClock > atom.clock
    return 0;
  }

  /// somewhat redundent ?
  /// should be sorted only by LogicalClockBase [DESC]
  /// TODO AtomBase
  @override
  List<Atom> get history => _history.toList()..sort();
  final Set<Atom> _history = {};

  void _setField(Atom atom) {
    final key = atom.data.key;
    final value = atom.data.value;

    _internalObject[key] = value;
    _objFieldOriginIds[key] = atom.id;

    // lookup if it is on object reference
    if (value is ObjectReference) {
      _syncableObjects[key] = _accessor.objectLookup(value);
    }
  }

  /// looks up first if something is in synable object else in the
  /// regular object by this key
  @override
  dynamic operator [](key) {
    return _syncableObjects[key] ?? _internalObject[key];
  }

  /// sets the values
  @override
  operator []=(field, value) => _sendToSyncLayer(field, value);

  /// once a field gets set, this will send the update action via
  /// [container.update]. This will create an Atom and sends it back to
  /// apply to the [_internalObject] through the synclayer
  ///
  /// THINK: maybe a short cut could be created?
  void _sendToSyncLayer(String field, value) {
    var val = value;

    // check if value is [SyncableObject]
    if (value is SyncableObject) {
      // create Ref type
      val = ObjectReference(value.type, value.id);
    }

    _accessor.onUpdate([Value(type, id, field, val)]);
  }

  /// lexographical sort by Object ID
  @override
  int compareTo(SyncableObject other) {
    for (var i = 0; i < id.length; i++) {
      final lc = id.codeUnitAt(i);
      final oc = other.id.codeUnitAt(i);

      // if (lc > oc) return 1;
      // if (lc < oc) return -1;
      if (lc != oc) return lc - oc;
    }

    return 0;
  }

  @override
  String toString() {
    final obj = {};
    for (final key in _internalObject.keys) {
      obj[key] = {
        'v': _internalObject[key],
        'c': _objFieldOriginIds[key]?.toString(),
      };
    }

    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(obj);
  }
}
