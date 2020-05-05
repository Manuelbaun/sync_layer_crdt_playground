import 'package:sync_layer/db/row.dart';
import 'package:sync_layer/sync/sync_imple.dart';

class Table {
  final String name;
  final SyncLayerImpl syn;
  Map<String, Row> rows;

  Table(this.name, this.syn) : rows = {};

  /// created new row if not exits
  Row getRow(String id) {
    rows[id] ??= Row(id, this);
    return rows[id];
  }

  @override
  String toString() {
    return '$name: ${rows.length}';
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
