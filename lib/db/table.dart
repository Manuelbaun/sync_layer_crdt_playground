import 'dart:async';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/db/row.dart';
import 'package:sync_layer/sync/sync_imple.dart';

class Table<T> {
  final String name;
  final SyncLayerImpl syn;
  Map<String, Row> rows;
  Map<String, T> entries = {}; // the real elements

  final updatedEntryController = StreamController<List<T>>();
  Stream<List<T>> get updatedEntryStream => updatedEntryController.stream;

  Table(this.name, this.syn) : rows = {};

  void triggerIdUpdate(Set<String> ids) {
    throw AssertionError('please override me');
  }

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
