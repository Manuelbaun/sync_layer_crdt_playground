import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/syncable_object_impl.dart';

class Todo extends SyncableObjectImpl {
  Todo(Accessor accessor, {String id, String title}) : super(id, accessor);

  String get title => super[0];
  set title(String v) => super[0] = v;

  bool get status => super[1];
  set status(bool v) => super[1] = v;

  Assignee get assignee => super[2];
  set assignee(Assignee v) => super[2] = v;

  @override
  String toString() {
    if (tombstone) return 'Todo($objectId, deleted: $tombstone)';

    return 'Todo($objectId, $title : $lastUpdated)';
  }
}

class Assignee extends SyncableObjectImpl {
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
    return 'Assignee($objectId, $firstName, $lastName, $age : $lastUpdated)';
  }
}
