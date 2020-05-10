import 'package:sync_layer/sync2/impl/index.dart';

class Todo2 extends SyncableObjectImpl {
  Todo2(SyncableObjectContainerImpl<Todo2> con, {String id, String title}) : super(id, con);

  String get title => super['title'];
  set title(String v) => super['title'] = v;

  Assignee get assignee => super['assignee'];
  set assignee(Assignee v) => super['assignee'] = v;

  @override
  String toString() {
    return 'Todo($id, $title, $assignee, $lastUpdated)';
  }
}

class Assignee extends SyncableObjectImpl {
  Assignee(SyncableObjectContainerImpl<Assignee> con, {String id, String title}) : super(id, con);

  String get firstName => super['firstName'];
  set firstName(String v) => super['firstName'] = v;

  String get lastName => super['lastName'];
  set lastName(String v) => super['lastName'] = v;

  int get age => super['age'];
  set age(int v) => super['age'] = v;

  List<Todo2> get todos => super['todos'];
  set todo(List<Todo2> v) => super['todos'] = v;

  @override
  String toString() {
    return 'Assignee($id, $firstName, $lastName, $age ${todos?.length}: $lastUpdated)';
  }
}
