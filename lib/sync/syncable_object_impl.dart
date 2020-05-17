import 'dart:convert';

import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';
import 'package:sync_layer/types/object_entry.dart';
import 'package:sync_layer/types/object_reference.dart';

import 'abstract/index.dart';

/// Meta fixed key numbers!
const int _TOMBSTONE = 0xFF00;

/// TODO Tombstone, revert option

class Entry {
  Entry(this.id, this.value);
  final IdBase id;
  final dynamic value;

  @override
  String toString() => 'Entry(id: $id, value: $value)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Entry && o.id == id && o.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;
}

class SyncableObjectImpl implements SyncableObject {
  /// **Important**
  ///
  /// if Id is not provided,  the container function generateID gets called!
  /// this function is provided by the sync layer, therefore the synclayer
  /// deceides which the form of the id

  SyncableObjectImpl(String id, Accessor accessor, {this.notify})
      : _accessor = accessor,
        assert(accessor != null, 'Accessor prop cannot be null'),
        _id = id ?? accessor.generateID() {
    /// direct set! no Id/Ts
    _internal[_TOMBSTONE] = Entry(null, false);
  }

  final Accessor _accessor;

  Function(int key, Entry entry) notify;

  /// Stores the key /values of the keys, specify by the user.
  /// in case of a synable object, it stores the type and id
  final Map<int, Entry> _internal = {};

  /// Stores the reference to the syncable Object, once it gets called, not present if not called
  /// => lazy
  final Map<int, SyncableObject> _syncableObjectsRefs = {};

  /// Getter Setter

  @override
  int get type => _accessor.type;

  @override
  String get objectId => _id;
  final String _id;

  /// Marks if the object is deleted!
  @override
  bool get tombstone => _getValue(_TOMBSTONE);

  @override
  set tombstone(bool v) => _setValue(_TOMBSTONE, v);

  /// Internal get and setter
  @pragma('vm:prefer-inline')
  SyncableObject _getSyncableObjectRef(int key) => _syncableObjectsRefs[key];

  @pragma('vm:prefer-inline')
  void _setSyncableObjectRef(int key, SyncableObject obj) => _syncableObjectsRefs[key] = obj;

  @pragma('vm:prefer-inline')
  dynamic _getValue(int key) => _internal[key]?.value;

  /// gets the Id base as timestamp and site id
  @pragma('vm:prefer-inline')
  IdBase _getIdTs(int key) => _internal[key]?.id;

  /// set value should only be used by apply atom,
  /// since this sets the _internal object with the object entry
  @pragma('vm:prefer-inline')
  void __setInternalValue(int key, Entry entry) {
    _internal[key] = entry;

    if (notify != null) notify(key, entry);
  }

  /// once a key gets set, this will send the update action via
  /// [container.update]. This will create an Atom and sends it back to
  /// apply to the [_internal] through the synclayer
  ///
  /// THINK: maybe a short cut could be created?
  ///
  void _setValue(int key, dynamic value) {
    /// check if value is [SyncableObject] and if so create Ref to object of type
    if (value is SyncableObject) {
      value = ObjectReference(value.type, value.objectId);
    }

    final atom = _accessor.onUpdate(objectId, SyncableEntry(key, value));

    /// Todo: set atom entry now?....
  }

  // @pragma('vm:prefer-inline')
  // dynamic _getMeta(int key) => _internalMeta[key];

  // @pragma('vm:prefer-inline')
  // void _setMeta(int key, value) => _internalMeta[key] = value;

  @override
  IdBase getFieldOriginId(int key) => _getIdTs(key);

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
  dynamic operator [](int key) => _getSyncableObjectRef(key) ?? _getValue(key);

  /// sets the value, send [FIRST] to sync layer, create atom, and then apply
  @override
  operator []=(int key, dynamic value) => _setValue(key, value);

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
    /// use
    final originId = _getIdTs(atom.data.key);

    /// TODO: what todo with history
    final isSet = _history.add(atom);

    // the same atom should not happen, this will only happen, if
    // the atom is not filtered out
    if (originId == atom.id) return 1;

    // if key was not set or the local time happend before [hb] to new Atom
    if (originId == null || (originId < atom.id)) {
      _applyUpdate(atom);
      return 2;
    }

    // if keyClock > atom.clock
    return 0;
  }

  void _applyUpdate(AtomBase atom) {
    // update the lastUpdated key
    if (_lastUpdated == null || _lastUpdated < atom.id) {
      _lastUpdated = atom.id;
    }

    final data = atom.data as SyncableEntry<int, dynamic>;

    __setInternalValue(data.key, Entry(atom.id, data.value));

    // lookup if it is on object reference
    if (data.value is ObjectReference) {
      final obj = _accessor.objectLookup(data.value);
      _setSyncableObjectRef(data.key, obj);
    }
  }

  /// lexographical sort by Object ID
  @override
  int compareTo(SyncableObject other) {
    for (var i = 0; i < objectId.length; i++) {
      final lc = objectId.codeUnitAt(i);
      final oc = other.objectId.codeUnitAt(i);
      final res = lc.compareTo(oc);
      if (res != 0) return res;
    }

    return 0;
  }

  /// TODO: compare by lastUpdated

  @override
  String toString() {
    final obj = {};
    for (final key in _internal.keys) {
      obj[key] = {
        'v': _internal[key].value,
        'c': _internal[key].id,
      };
    }

    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(obj);
  }
}
