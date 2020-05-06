import 'package:sync_layer/db/index.dart';
import 'package:sync_layer/sync/sync_imple.dart';

import '../dto/assignee.dart';

class AssigneeTable extends Table {
  AssigneeTable(String name, SyncLayerImpl syn) : super(name, syn);

  Assignee create(String department, String firstname, String lastname) {
    return Assignee(getRow(), department: department, firstname: firstname, lastname: lastname);
  }

  Assignee read(String id) {
    return Assignee(getRow(id));
  }

  Assignee update() {}
  bool delete() {}
}
