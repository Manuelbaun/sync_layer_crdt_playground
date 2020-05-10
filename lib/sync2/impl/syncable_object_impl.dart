import 'package:sync_layer/basic/hlc.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/sync2/abstract/index.dart';

class SyncableObjectImpl implements SyncableObject {
  @override
  String get id => _id;
  final String _id;

  /// Ref to the Table
  final SyncableObjectContainer _container;
  @override
  SyncableObjectContainer get container => _container;

  /// Marks if the object is deleted!
  @override
  bool get tompstone => this['tompstone'];

  @override
  set tompstone(bool v) => this['tomestone'] = v;

  /// the actual object data
  final Map<String, dynamic> _obj = {};
  final Map<String, SyncableObject> _synableObjects = {};
  final Map<String, Hlc> _objHlc = {};

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
    /// TODO: create Tompstone field!
    /// without HLC => default false or 0
  }

  /// Returns the timestamp for that field
  @override
  Hlc getCurrentTsOfField(String field) => _objHlc[field];

  @override
  Hlc get lastUpdated => _objHlc.values.reduce((a, b) => a > b ? a : b);

  /// applies atom:
  /// * if successfull => returns [2]
  /// * if atom is older then current value => returns [1] :
  /// * else => returns [-1]
  ///
  @override
  int applyAtom(Atom atom) {
    final currentTs = getCurrentTsOfField(atom.key);

    // if field was not set or the local time happend before [hb] to new Atom
    if (currentTs == null || Hlc.compareWithNodes(currentTs, atom.ts)) {
      _setField(atom);
      _updateHistory(atom);
      return 2;
    }

    /// if atoms.ts < currentTs => true
    if (Hlc.compareWithNodes(atom.ts, currentTs)) {
      _updateHistory(atom);
      return 1;
    }

    return -1;
  }

  void _updateHistory(Atom atom) {
    history.add(atom);
    history.sort((a, b) => b.ts.logicalTime - a.ts.logicalTime);
  }

  void _setField(Atom atom) {
    _obj[atom.key] = atom.value;
    _objHlc[atom.key] = atom.ts;

    if (atom.value is Map) {
      final m = atom.value as Map;

      if (m['_typeId'] != null && m['_id'] != null) {
        _synableObjects[atom.key] = _lookUpSynableObject(m['_typeId'], m['_id']);
      }
    }
  }

  @override
  dynamic operator [](key) {
    return _synableObjects[key] ?? _obj[key];
  }

  /// should create shortcut to update the field directly???
  @override
  operator []=(field, value) {
    container.update(_id, field, _syncableObjToTypeAndID(value));
  }

  dynamic _syncableObjToTypeAndID(dynamic value) {
    if (value is SyncableObject) {
      return {'_typeId': value.container.typeId, '_id': value.id};
    }
    return value;
  }

  SyncableObject _lookUpSynableObject(typeId, id) {
    final con = _container.syn.getObjectContainer(typeId);
    return con.getEntry(id);
  }
}

// var val;
// if (list[5] is Map) {
//   final m = list[5] as Map;

//   if (m['typeId'] != null && m['id'] != null) {}
// }
