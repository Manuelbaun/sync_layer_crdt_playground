import 'package:sync_layer/sync2/impl/index.dart';

class Todo2 extends SyncableObjectImpl {
  Todo2(SyncableObjectContainerImpl<Todo2> con, {String id, String title}) : super(id, con);

  String get title => super['title'];
  set title(String v) => super['title'] = v;
}

class Assignee extends SyncableObjectImpl {
  Assignee(SyncableObjectContainerImpl<Assignee> con, {String id, String title}) : super(id, con);
}
