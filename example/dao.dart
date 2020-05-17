import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/syncable_object_impl.dart';

class Todo extends SyncableObjectImpl<int> {
  Todo(Accessor accessor, {String id, String title}) : super(id, accessor);

  String get title => super[0];
  set title(String v) => super[0] = v;

  bool get status => super[1];
  set status(bool v) => super[1] = v;

  Assignee get assignee => super[2];
  set assignee(Assignee v) => super[2] = v;

  @override
  String toString() {
    if (tombstone) return 'Todo($id, deleted: $tombstone)';
    return 'Todo($id, $title : $lastUpdated)';
  }
}

class Assignee extends SyncableObjectImpl<int> {
  Assignee(Accessor accessor, {String id, String title}) : super(id, accessor);

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

void setupDaos(SyncLayer syn) {
  // final todoFactory = (Accessor<Map<int, dynamic>> c, String id) => Todo(c, id: id);
  // final assigneeFactory = (Accessor<Map<int, dynamic>> c, String id) => Assignee(c, id: id);

  // final daoTodo = syn.registerObjectType<Todo>('todos', todoFactory);
  // final daoAss = syn.registerObjectType<Assignee>('assignee', assigneeFactory);
}
