import 'dart:convert';

import 'package:sync_layer/sync/message.dart';

class Row {
  String id;
  // history just for fast lookup!
  List<SyncMessage> history;
  // the actual object data
  Map<String, dynamic> obj;

  /// History, youngest message first!
  Row(this.id)
      : history = [],
        obj = {};

  // only add messages!!!
  void add(SyncMessage msg) {
    obj[msg.column] = msg.value;
    history.add(msg);
    history.sort();
  }

  String prettyJson() {
    var encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({'_id': id, ...obj});
  }

  /// gets the latest column sync message if exist. else null
  SyncMessage getLastestColumnUpdate(SyncMessage msg) {
    // search reversed
    for (var i = history.length - 1; i >= 0; i--) {
      final m = history[i];
      if (m.column == msg.column) return m;
    }
    return null;
  }

  @override
  String toString() {
    return 'Row(id: $id : history-length: ${history.length})';
  }
}
