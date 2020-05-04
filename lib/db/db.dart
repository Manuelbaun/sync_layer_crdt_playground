import 'dart:convert';

import 'package:sync_layer/basic/merkle_tire_node.dart';
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
}

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

class DB {
  /// contains all received messages
  final Map<String, Table> _db = {};

  // for quick access and sync between client
  final List<SyncMessage> _allMessages = [];

  // remembers if messages already exits
  final Set<int> _allMessagesHashcodes = {};

  /// the root of the merkle tree

  DB([MerkleTrie trie]);

  void addToAllMessage(SyncMessage msg) {
    _allMessages.add(msg);
    _allMessagesHashcodes.add(msg.hashCode);

    // reversed??
    _allMessages.sort();
  }

  Table getTable(String table) => _db[table.toString()];
  bool tableExist(String table) => _db.containsKey(table.toLowerCase());

  void createTable(String table) => _db[table.toLowerCase()] ??= Table(table.toLowerCase());

  bool messageExistInLocalSet(SyncMessage msg) => _allMessagesHashcodes.contains(msg.hashCode);

  List<SyncMessage> getMessagesSince(int logicalTime) {
    return _allMessages.where((msg) => msg.ts.logicalTime > logicalTime).toList();
  }
}
