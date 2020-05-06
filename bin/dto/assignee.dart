import 'package:sync_layer/db/row.dart';

class Assignee {
  final Row row;
  String get id => row.id;

  Assignee(this.row, {String department, String firstname, String lastname}) : assert(row != null) {
    if (department != null) this.department ??= department;
    if (firstname != null) this.firstname ??= firstname;
    if (lastname != null) this.lastname ??= lastname;
  }

  String get department => row['department'];
  set department(String value) => row['department'] = value;

  String get firstname => row['firstname'];
  set firstname(String value) => row['firstname'] = value;

  String get lastname => row['lastname'];
  set lastname(String value) => row['lastname'] = value;

  @override
  String toString() {
    return 'Assignee(${row.obj}: hlc:${row.lastUpdated})';
  }
}
