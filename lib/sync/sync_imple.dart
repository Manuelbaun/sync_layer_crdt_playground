import 'dart:convert';

import 'package:sync_layer/basic/merkle_tire_node.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/db/index.dart';

import 'clock.dart';

typedef ChangedRows = void Function(Set<Row> rows, Set<Table> tabels);

class SyncLayerImpl {
  final DB db = DB();
  final Clock clock;
  final String nodeId;

  ChangedRows onChange;
  Function onSend;
  Function onReceived;

  SyncLayerImpl(this.nodeId) : clock = Clock(nodeId);

  /// apply assumes, messages are not present in the db!
  void applyMessages(List<Atom> messages) {
    final changedRows = <Row>{};
    final changedTables = <Table>{};

    for (final msg in messages) {
      if (!db.messageExistInLocalSet(msg)) {
        // test if table exits
        final table = db.getTable(msg.table);
        if (table != null) {
          changedTables.add(table);
          // if row does not exist, new row will be added
          final row = table.getRow(msg.row);
          final obj = row.getLastestColumnUpdate(msg);

          // Add value to row
          if (obj == null || obj.ts < msg.ts) {
            row.add(msg);
            changedRows.add(row);
          }

          /// stores message in db
          if (obj == null || obj.ts != msg.ts) {
            db.addToAllMessage(msg);
            // addes messages to trie
            clock.merkle.build([msg.ts]);
          } else {
            /// is it possible for two messages from different note to have the same ts?
            if (obj.ts.node != msg.ts.node) {
              // what should happen now?
              print('Two Timestamps have the exact same logicaltime on two different nodes! $obj - $msg');
              // Todo: Throw error
            }
          }
        } else {
          print('Table does not exist');
          // Todo: Throw error

        }
      } // else skip that message
    }

    if (onChange != null) onChange(changedRows, changedTables);
  }

  void receivingMessages(List<Atom> messages) {
    messages.forEach((msg) {
      clock.fromReveive(msg.ts);
    });

    applyMessages(messages);
  }

  void sendMessages(List<Atom> messages) {
    applyMessages(messages);
    synchronize(messages);
  }

  /// [since] in millisecond
  void synchronize(List<Atom> messages, [int since]) async {
    if (since != null && since != 0) {
      var ts = clock.getHlc(since, 0, nodeId);
      messages = db.getMessagesSince(ts.logicalTime);
    }

    /// send via network!
    if (onSend != null) {
      onSend(messages);
    }
  }

  Atom createMsg(String table, String row, String column, dynamic value) {
    return Atom(clock.getForSend(), table, row, column, value);
  }

  void onIncomingJsonMsg(List<dynamic> msgs) {
    final messages = msgs.map((map) {
      return Atom.fromMap(json.decode(map));
    }).toList();

    receivingMessages(messages);
  }

  List<Atom> getDiffMessagesFromIncomingMerkleTrie(Map merkleMap) {
    final clientMerkle = MerkleTrie.fromMap(merkleMap, 36);
    final tsString = clock.merkle.diff(clientMerkle);

    if (tsString != null) {
      // minutes to ms
      final ts = int.parse(tsString, radix: 36) * 60000;
      // minutes to logicalTime

      final messagestoSend = db.getMessagesSince(ts << 16);
      return messagestoSend;
    }
    return [];
  }

  // void onUpdate(String table, String row, String column, dynamic value) {
  //   final msg = Atom(clock.getForSend(), table, row, column, value);
  //   applyMessages([msg]);
  // }

  // @override
  // void registerTable<T>(SyncableTable<T> obj) {
  //   if (_db[obj.tableId] == null) {
  //     // add Table to _db
  //     _db[obj.tableId] = <String, T>{};
  //     _tableMapper[obj.name] = obj;
  //     final table = _db[obj.tableId];

  //     obj.setDbTable(table);

  //     obj.streamMessage.listen((msg) {});
  //   } else {
  //     throw AssertionError('Table with id: ${obj.tableId} already registere#');
  //   }
  // }

  // @override
  // void addMessage(SyncMessage msg) {
  //   if (!_allMessages.containsKey(msg)) {
  //     _allMessages[msg.id] = msg.msg;
  //     _trieRoot.build([Hlc.fromLogicalTime(msg.id.ts)]);

  //     _tableMapper[msg.msg.table].applyMessage(msg);
  //   }
  // }

  // @override
  // List<SyncMessage> getMessagesSince(int hypelogicalClock) {
  //   throw AssertionError('Please implement me!');
  // }

  // @override
  // int compareTries(String trieMap) {
  //   throw AssertionError('Please implement me!');
  // }

  // @override
  // String getTrieJson() {
  //   return _trieRoot.toJson();
  // }
}
