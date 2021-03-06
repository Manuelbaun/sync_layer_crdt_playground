import 'acess_proxy.dart';
import 'syncable_base.dart';

typedef SynableObjectFactory<T> = T Function(AccessProxy accessor, String id);

abstract class SyncableObjectContainer<T extends SyncableBase> {
  int get type;
  int get length;

  Stream<Set<T>> get changeStream;

  /// added this object to a set of objects, which will be send via [changeStream]
  /// as updated objects
  void setUpdatedObject(String objectId);

  /// this will trigger an update, all objects set via setUpdatedObject will be
  /// send via [changeStream]
  void triggerUpdateChange();

  /// returns a list of all objects in this container
  List<T> allObjects();

  /// CRUD Ops Public API

  /// creates new object if id is null it created a new cuid
  T create([String objectId]);

  /// returns null if not exist or deleted
  T read(String objectId);

  /// updates an object field with value by id
  void update(String objectId, int key, dynamic value);

  ///
  bool delete(String objectId);
}
