import 'package:sync_layer/db/index.dart';
import 'package:sync_layer/sync/sync_imple.dart';

import '../dto/todo.dart';

class TodoTable extends Table<Todo> {
  TodoTable(String name, SyncLayerImpl syn) : super(name, syn);

  Todo create(String title, {bool status = false}) {
    final row = getRow();
    final todo = Todo(row, title: title, status: status);
    entries[todo.id] = todo;
    return todo;
  }

  Todo read(String id) {
    final row = getRow(id);
    return Todo(row);
  }

  Todo update() {}
  bool delete() {}

  @override
  void triggerIdUpdate(Set<String> ids) {
    final allUpdatedEntries = ids.map((id) => read(id)).toList();

    if (allUpdatedEntries.isNotEmpty) {
      updatedEntryController.add(allUpdatedEntries);
    }
  }
}
