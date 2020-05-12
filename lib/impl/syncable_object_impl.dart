import 'package:sync_layer/timestamp/index.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/abstract/index.dart';

const String _TOMBSTONE = '_tombstone';
const String _TYPEID = '_typeId';
const String _OBJID = '_objid';

class SyncableObjectImpl implements SyncableObject {
  @override
  String get id => _id;
  final String _id;

  /// Ref to the Table
  @override
  SyncableObjectContainer get container => _container;
  final SyncableObjectContainer _container;

  /// Marks if the object is deleted!
  @override
  bool get tombstone => this[_TOMBSTONE];

  @override
  set tombstone(bool v) => this[_TOMBSTONE] = v;

  /// Stores the key /values of the fields, specify by the user.
  /// in case of a synable object, it stores the type and id
  final Map<String, dynamic> _obj = {};
  final Map<String, Hlc> _objHlc = {};

  /// Stores the reference to the syncable Object
  final Map<String, SyncableObject> _syncableObjects = {};

  // somewhat redundet
  final List<Atom> history = [];

  /// **Important**
  ///
  /// if Id is not provided,  the container function generateID gets called!
  /// this function is provided by the sync layer, therefore the synclayer
  /// deceides which the form of the id
  SyncableObjectImpl(String id, SyncableObjectContainer container)
      : assert(container != null, 'Table prop cant be null'),
        _container = container,
        _id = id ?? container.generateID() {
    // define and set tombstone to false;
    _obj[_TOMBSTONE] = false;

    /// without HLC => default false or 0
  }

  /// Returns the timestamp for that field
  @override
  Hlc getCurrentHLCOfField(String field) => _objHlc[field];

  // TODO: could be set with [applyAtoms]
  @override
  Hlc get lastUpdated {
    if (_objHlc.isNotEmpty) return _objHlc.values?.reduce((a, b) => a > b ? a : b);
    return null;
  }

  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom is older then current value
  /// * returns [-1] : else
  @override
  int applyAtom(Atom atom) {
    final currentTs = getCurrentHLCOfField(atom.key);

    // if field was not set or the local time happend before [hb] to new Atom
    if (currentTs == null || Hlc.compareWithNodes(currentTs, atom.hlc)) {
      _setField(atom);
      _updateHistory(atom);
      return 2;
    }

    // if atoms.ts < currentTs => true
    if (Hlc.compareWithNodes(atom.hlc, currentTs)) {
      _updateHistory(atom);
      return 1;
    }

    return -1;
  }

  /// adds internally to the history log!
  /// TODO: what can be done with this...
  /// DB lookups?
  void _updateHistory(Atom atom) {
    history.add(atom);
    history.sort((a, b) => b.hlc.logicalTime - a.hlc.logicalTime);
  }

  void _setField(Atom atom) {
    _obj[atom.key] = atom.value;
    _objHlc[atom.key] = atom.hlc;

    if (atom.value is Map) {
      final m = atom.value as Map;

      final String type = m[_TYPEID];
      final String objId = m[_OBJID];

      // if it is a synable object look it up and store it in the [_syncableObjects]
      if (type != null && objId != null) {
        _syncableObjects[atom.key] = _lookUpSynableObject(type, objId);
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
    final val = _syncableObjToTypeAndID(value);
    _container.update(_id, field, val);
  }

  /// this function checks wheter value is a syncable object or not.
  /// If so, store the reference as type id and object id
  /// else pass the value through
  dynamic _syncableObjToTypeAndID(dynamic value) {
    if (value is SyncableObject) {
      return {_TYPEID: value.container.typeId, _OBJID: value.id};
    }
    return value;
  }

  /// looks up the syncable object by the container given by the typeId
  SyncableObject _lookUpSynableObject(String typeId, String id) {
    final con = _container.syn.getObjectContainer(typeId);
    var obj = con.read(id);
    obj ??= con.create(id);
    return obj;
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
}
