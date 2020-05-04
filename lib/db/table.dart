import 'package:sync_layer/db/row.dart';

class Table {
  final String name;
  Map<String, Row> rows;
  Table(this.name) : rows = {};

  /// created new row if not exits
  Row getRow(String id) {
    rows[id] ??= Row(id);
    return rows[id];
  }
}
