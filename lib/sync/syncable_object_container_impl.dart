import 'dart:async';

import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/logger/index.dart';

import 'abstract/index.dart';

class SyncableObjectContainerImpl<T extends SyncableObject> implements SyncableObjectContainer<T> {
  final Map<String, T> _objects = {}; // the real elements
  final SynableObjectFactory<T> _objectFactory;
  final _controller = StreamController<Set<T>>.broadcast();
  final _updatedObjects = <T>{};

  /// this returns the length of the container **with** delted Objects!
  /// TODO: filter out tombstoned objects
  @override
  int get length {
    return _objects.length;
  }

  @override
  // final SyncLayer syn;

  @override
  Stream<Set<T>> get changeStream => _controller.stream;

  @override
  List<T> allObjects() {
    final o = _objects.values.where((o) => o.tombstone == false).toList();
    if (o.isNotEmpty) {
      o.sort();
    }
    return o;
  }

  @override
  void setUpdatedObject(T obj) {
    _updatedObjects.add(obj);
  }

  @override
  void triggerUpdateChange() {
    _controller.add({..._updatedObjects});
    _updatedObjects.clear();
  }

  @override
  int get type => accessor.type;

  /// Provide a default factory function for that Syncable Object

  SyncableObjectContainerImpl(this.accessor, this._objectFactory)
      : assert(accessor != null),
        assert(_objectFactory != null);

  final Accessor accessor;

  ///
  /// CRUD Ops
  /// Public API
  ///

  /// creates new object
  @override
  T create([String id]) {
    var obj = _get(id);

    if (obj == null) {
      // creates new object with provided ID
      obj = _objectFactory(accessor, id);
      return _set(obj);
    } else if (obj.tombstone == true) {
      /// Creates new ID for previous deleted object!
      logger.error('Cannot recreate by the same id $type - $id. Will return same old object');
      return obj;
    } else

    // if object exist, and is not deleted! => cant create
    if (obj != null && !obj.tombstone) {
      throw AssertionError('Cant create Object because ID "$id" already exist');
    }

    throw AssertionError('This should never happen: Some missing cases when create Object is called. Debug me!');
  }

  SyncableObject _set(SyncableObject obj) {
    _objects[obj.id] = obj;
    return _objects[obj.id];
  }

  SyncableObject _get(String id) {
    return _objects[id];
  }

  /// returns null if not exist or deleted
  @override
  T read(String id) {
    final o = _get(id);
    // if not deleted
    if (o != null && o.tombstone == false) return o;
    // if deleted
    return null;
  }

  /// updates an object ???
  // gets called from the sync object
  @override
  void update(String id, String field, dynamic value) {
    accessor.onUpdate([Value(type, id, field, value)]);
  }

  ///
  @override
  bool delete(String id) {
    final t = read(id);
    if (t != null) {
      t.tombstone = true;
      return true;
    }
    return false;
  }
}
