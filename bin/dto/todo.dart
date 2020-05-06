import 'package:sync_layer/db/index.dart';

import 'assignee.dart';

class Todo {
  final Row row;
  String get id => row.id;

  Todo(this.row, {String title, bool status}) : assert(row != null) {
    if (title != null) this.title ??= title;
    if (status != null) this.status ??= status;
  }

  String get title => row['title'];
  set title(String v) => row['title'] = v;

  bool get status => row['status'];
  set status(bool v) => row['status'] = v;

  Assignee get assignee => row['assignee'];
  set assignee(Assignee v) => row['assignee'] = v;

  @override
  String toString() {
    final rowData = row.toString();
    return 'Todo($rowData , hlc: ${row.lastUpdated})';
  }
}
