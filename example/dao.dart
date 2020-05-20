import 'package:sync_layer/index.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';
import 'package:sync_layer/sync/syncable_causal_tree.dart';
import 'package:sync_layer/sync/syncable_object_impl.dart';

class Todo extends SyncableObjectImpl<int, Todo> {
  Todo(AccessProxy proxy, {String id, String title}) : super(proxy, id);

  SyncArray get title => super[0];
  set title(SyncArray v) => super[0] = v;

  bool get status => super[1];
  set status(bool v) => super[1] = v;

  Assignee get assignee => super[2];
  set assignee(Assignee v) => super[2] = v;

  @override
  String toString() {
    if (tombstone) return 'Todo($id, deleted: $tombstone)';
    return 'Todo($id, $title : $lastUpdated)';
  }

  Map toJson() {
    return {
      '_meta_': {
        'id': id,
        'tombstone': tombstone,
        'lastUpdated': lastUpdated,
      },
      'title': super[0],
      'status': super[1],
      // issue with hidden object ref!
      // 'assignee': super[2].toJson(),
    };
  }
}

class Assignee extends SyncableObjectImpl<int, Assignee> {
  Assignee(AccessProxy proxy, {String id}) : super(proxy, id);

  String get firstName => super[0];
  set firstName(String v) => super[0] = v;

  String get lastName => super[1];
  set lastName(String v) => super[1] = v;

  int get age => super[2];
  set age(int v) => super[2] = v;

  Todo get todo => super[3];
  set todo(Todo v) => super[3] = v;

  @override
  String toString() {
    return 'Assignee($id, $firstName, $lastName, $age : $lastUpdated)';
  }
}

class SyncArray extends SyncableCausalTree {
  SyncArray(AccessProxy accessor, {String id}) : super(accessor, id);
}

class SyncText extends SyncableCausalTree {
  SyncText(AccessProxy accessor, {String id}) : super(accessor, id);
}

class SyncDao {
  static SyncDao _instance;
  static SyncDao get instance => _instance;

  static SyncDao getInstance(int nodeId) {
    _instance ??= SyncDao(nodeId);
    return _instance;
  }

  final int nodeID;

  SyncDao(this.nodeID) {
    if (_instance == null) {
      _syn = SyncLayerImpl(nodeID);
      _protocol = SyncLayerProtocol(_syn);

      // create first container by type
      _todos = _syn.registerObjectType<Todo>('todos', (c, id) => Todo(c, id: id));
      _assignees = _syn.registerObjectType<Assignee>('assignee', (c, id) => Assignee(c, id: id));
      _syncArray = syn.registerObjectType<SyncArray>('syncarray', (c, id) => SyncArray(c, id: id));

      // setupListener();
    } else {
      throw AssertionError('cant create this class twice?');
    }
  }

  void setupListener() {
    syncArray.changeStream.listen((objs) {
      objs.forEach((o) => logger.info(o.entries.toString()));
    });

    todos.changeStream.listen((objs) {
      objs.forEach((o) => logger.info(o.toString()));
    });

    assignees.changeStream.listen((objs) => objs.forEach((o) => logger.info(o.toString())));
  }

  SyncLayerProtocol _protocol;
  SyncLayerProtocol get protocol => _protocol;

  SyncLayerImpl _syn;
  SyncLayerImpl get syn => _syn;

  SyncableObjectContainer<Todo> get todos => _todos;
  SyncableObjectContainer<Todo> _todos;

  SyncableObjectContainer<Assignee> get assignees => _assignees;
  SyncableObjectContainer<Assignee> _assignees;

  SyncableObjectContainer<SyncArray> get syncArray => _syncArray;
  SyncableObjectContainer<SyncArray> _syncArray;
}
