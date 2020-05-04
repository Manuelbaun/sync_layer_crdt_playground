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

  @override
  String toString() {
    return '$name[s]: ${rows.length}';
  }

  @override
  Map toMap() {
    final entries = {};
    for (final entry in rows.entries) {
      entries[entry.key] = entry.value.obj;
    }

    return {'table': name, 'entries': entries};
  }
}
