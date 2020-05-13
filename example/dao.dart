import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';

class Todo extends SyncableObjectImpl {
  Todo(Accessor accessor, {String id, String title}) : super(id, accessor);

  String get title => super['title'];
  set title(String v) => super['title'] = v;

  bool get status => super['status'];
  set status(bool v) => super['status'] = v;

  Assignee get assignee => super['assignee'];
  set assignee(Assignee v) => super['assignee'] = v;

  @override
  String toString() {
    if (tombstone) return 'Todo($id, deleted: $tombstone)';

    return 'Todo($id, $title : $lastUpdated)';
  }
}

class Assignee extends SyncableObjectImpl {
  Assignee(Accessor accessor, {String id, String title}) : super(id, accessor);

  String get firstName => super['firstName'];
  set firstName(String v) => super['firstName'] = v;

  String get lastName => super['lastName'];
  set lastName(String v) => super['lastName'] = v;

  int get age => super['age'];
  set age(int v) => super['age'] = v;

  Todo get todo => super['todos'];
  set todo(Todo v) => super['todos'] = v;

  @override
  String toString() {
    return 'Assignee($id, $firstName, $lastName, $age : $lastUpdated)';
  }
}
