import 'impl/index.dart';

class Todo2 extends SyncableObjectImpl {
  Todo2(SyncableObjectContainerImpl<Todo2> con, {String id, String title}) : super(id, con);

  String get title => super['title'];
  set title(String v) => super['title'] = v;
}

class Assignee extends SyncableObjectImpl {
  Assignee(SyncableObjectContainerImpl<Assignee> con, {String id, String title}) : super(id, con);
}

/// --------------------------------------------------------------
/// --------------------------------------------------------------
/// --------------------------------------------------------------
void main() {
  final syn = SyncLayerImpl('local');
  final con = syn.registerObjectType<Todo2>('todos', (c) => Todo2(c));
  final conTodo = syn.getObjectContainer<Todo2>('todos');
  final t = con.create();
  t.title = "hallo";
  print(t);
}
