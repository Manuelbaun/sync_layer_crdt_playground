import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/db/row.dart';
import 'package:sync_layer/sync/sync_imple.dart';

class Table {
  final String name;
  final SyncLayerImpl syn;
  Map<String, Row> rows;

  // the real elements
  Map<String, dynamic> items = {};

  Table(this.name, this.syn) : rows = {};

  /// reads row or creates new row if not existed before!
  Row getRow([String id]) {
    final _id = id ?? newCuid();
    rows[_id] ??= Row(_id, this);
    return rows[_id];
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
