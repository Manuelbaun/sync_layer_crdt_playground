import 'sync_layer.dart';
import 'syncable_object.dart';

typedef SynableObjectFactory<T> = T Function(SyncableObjectContainer container, String id);

abstract class SyncableObjectContainer<T extends SyncableObject> {
  String get typeId;
  int get length;

  /// TODO: Refactor this and use a util injector or something else
  /// some sort of look up
  SyncLayer get syn;

  String generateID();
  Stream<Set<T>> get changeStream;
  void setUpdatedObject(T obj);
  void triggerUpdateChange();

  List<T> allObjects();

  /// CRUD Ops Public API

  /// creates new object if id is null it created a new cuid
  T create([String id]);

  /// returns null if not exist or deleted
  T read(String id);

  /// updates an object field with value by id
  void update(String objectId, String fieldId, dynamic value);

  ///
  bool delete(String id);
}
