import 'package:sync_layer/abstract/index.dart';

import 'syncable_object.dart';

typedef SynableObjectFactory<T> = T Function(Accessor container, String id);

abstract class SyncableObjectContainer<T extends SyncableObject> {
  String get type;
  int get length;

  Stream<Set<T>> get changeStream;

  /// added this object to a set of objects, which will be send via [changeStream]
  /// as updated objects
  void setUpdatedObject(T obj);

  /// this will trigger an update, all objects set via setUpdatedObject will be
  /// send via [changeStream]
  void triggerUpdateChange();

  /// returns a list of all objects in this container
  List<T> allObjects();

  /// CRUD Ops Public API

  /// creates new object if id is null it created a new cuid
  T create([String id]);

  /// returns null if not exist or deleted
  T read(String id);

  /// updates an object field with value by id
  void update(String id, String field, dynamic value);

  ///
  bool delete(String id);
}
