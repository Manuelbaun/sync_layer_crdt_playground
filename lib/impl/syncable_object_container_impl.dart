import 'dart:async';

import 'package:sync_layer/abstract/index.dart';
import 'package:sync_layer/crdts/values.dart';
import 'package:sync_layer/logger/index.dart';

class ContainerAccessorImpl implements ContainerAccessor {
  ContainerAccessorImpl(this.synclayer, this.container) {
    type = container.typeId;
  }

  final SyncableObjectContainer container;
  final SyncLayer synclayer;

  @override
  String type;

  @override
  void onUpdate(String id, String key, dynamic value) {
    final a = synclayer.createAtom(Value(type, id, key, value));
    synclayer.applyAtoms([a]);
  }

  @override
  String generateID() {
    return synclayer.generateID();
  }

  @override
  SyncableObject objectLookup(String type, String id, [bool shouldCreateIfNull = true]) {
    final container = synclayer.getObjectContainer(type);
    var obj = container.read(id);

    if (shouldCreateIfNull && obj == null) {
      obj = container.create(id);
    }
    return obj;
  }
}

class SyncableObjectContainerImpl<T extends SyncableObject> implements SyncableObjectContainer<T> {
  final String _typeId;
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
  String get typeId => _typeId;

  /// Provide a default factory function for that Syncable Object

  SyncableObjectContainerImpl(SyncLayer syn, String typeId, SynableObjectFactory<T> objectFactory)
      : assert(syn != null),
        assert(objectFactory != null),
        assert(typeId != null),
        _typeId = typeId.toLowerCase(),
        _objectFactory = objectFactory {
    // create accessor class for the synable objects
    accessor = ContainerAccessorImpl(syn, this);
  }

  ContainerAccessor accessor;

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
      logger.error('Cannot recreate by the same id $typeId - $id. Will return same old object');
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
  void update(String objectId, String fieldId, dynamic value) {
    accessor.onUpdate(objectId, fieldId, value);
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
