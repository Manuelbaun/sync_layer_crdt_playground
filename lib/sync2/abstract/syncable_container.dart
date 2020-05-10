import 'syncable_object.dart';

typedef SynableObjectFactory<T> = T Function(SyncableObjectContainer container);

abstract class SyncableObjectContainer<T extends SyncableObject> {
  String get typeId;

  /// **This is internal API**
  ///
  /// returns Entry of Type T if present in the entry Map
  /// else it creates a new Entry
  T getEntry(String id);

  String generateID();

  Stream<Set<T>> get changeStream;
  void setUpdatedObject(T obj);
  void triggerUpdateChange();

  ///
  /// CRUD Ops
  /// Public API
  ///

  /// creates new object
  T create();

  /// returns null if not exist or deleted
  T read(String id);

  /// updates an object ???
  // gets called from the sync object
  void update(String objectId, String fieldId, dynamic value);

  ///
  bool delete(String id);
}
