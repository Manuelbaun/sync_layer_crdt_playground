import 'package:sync_layer/sync2/abstract/index.dart';

class SyncableObjectContainerImpl<T extends SyncableObject> implements SyncableObjectContainer<T> {
  final String _typeId;
  final SyncLayer syn;
  final Map<String, T> _objects = {}; // the real elements
  final SynableObjectFactory<T> _objectFactory;

  @override
  String get typeId => _typeId;

  /// Provide a default factory function for that Syncable Object

  SyncableObjectContainerImpl(this.syn, String typeId, SynableObjectFactory<T> objectFactory)
      : assert(syn != null),
        assert(objectFactory != null),
        _typeId = typeId.toLowerCase(),
        _objectFactory = objectFactory;

  @override
  String generateID() => syn.generateID();

  /// **This is internal API**
  ///
  /// returns Entry of Type T if present in the entry Map
  /// else it creates a new Entry
  @override
  T getEntry(String id) {
    return read(id) ?? create();
  }

  ///
  /// CRUD Ops
  /// Public API
  ///

  /// creates new object
  @override
  T create() {
    final t = _objectFactory(this);
    _objects[t.id] = t;
    return t;
  }

  /// returns null if not exist or deleted
  @override
  T read(String id) {
    final t = _objects[id];
    if (t != null && t.tompstone != false) return t;
    return null;
  }

  /// updates an object ???
  // gets called from the sync object
  @override
  void update(String objectId, String fieldId, dynamic value) {
    final a = syn.createAtom(typeId, objectId, fieldId, value);
    syn.applyAtoms([a]);
  }

  ///
  @override
  bool delete(String id) {
    final t = read(id);
    if (t != null) {
      t.tompstone = true;
      return true;
    }
    return false;
  }
}
