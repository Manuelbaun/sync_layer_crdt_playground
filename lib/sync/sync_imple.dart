import 'dart:convert';

import 'package:sync_layer/basic/merkle_tire_node.dart';
import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/crdts/clock.dart';
import 'package:sync_layer/db/index.dart';

typedef ChangedRows = void Function(Set<Row> rows, Set<Table> tabels);

class SyncLayerImpl {
  DB _db;
  DB get db => _db;

  final String nodeId;

  ChangedRows onChange;
  Function onSend;
  Function onReceived;

  // Time Related
  final Clock clock;
  final MerkleTrie trie;

  SyncLayerImpl(this.nodeId, [MerkleTrie trie])
      : clock = Clock(nodeId),
        trie = trie ?? MerkleTrie() {
    _db = DB(this);
  }

  /// apply assumes, messages are not present in the db!
  void applyMessages(List<Atom> messages) {
    final changedRows = <Row>{};
    final changedTables = <Table>{};

    for (final msg in messages) {
      if (!_db.messageExistInLocalSet(msg)) {
        // test if table exits
        final table = _db.getTable(msg.classType);
        if (table != null) {
          changedTables.add(table);

          // if row does not exist, new row will be added
          final row = table.getRow(msg.id);
          final hlc = row.getColumnHlc(msg);

          // Add value to row
          if (hlc == null || hlc < msg.ts) {
            row.setColumnValueBySyncLayer(msg);
            changedRows.add(row);
          }

          /// stores message in db
          if (hlc == null || hlc != msg.ts) {
            _db.addToAllMessage(msg);
            // addes messages to trie
            trie.build([msg.ts]);
          } else {
            /// is it possible for two messages from different note to have the same ts?
            if (hlc.node != msg.ts.node) {
              // what should happen now?
              // TODO: sort by node?
              print('Two Timestamps have the exact same logicaltime on two different nodes! $hlc - $msg');
            }
          }
        } else {
          print('Table does not exist');
          // Todo: Throw error

        }
      } // else skip that message
    }

    if (onChange != null) {
      if (changedRows.isNotEmpty || changedTables.isNotEmpty) {
        onChange(changedRows, changedTables);
      }
    }
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
      messages = _db.getMessagesSince(ts.logicalTime);
    }

    /// send via network!
    if (onSend != null) {
      onSend(messages);
    }
  }

  Atom createAtom(String classType, String id, String column, dynamic value) {
    return Atom(clock.getForSend(), classType, id, column, value);
  }

  void onIncomingJsonMsg(List<dynamic> msgs) {
    final messages = msgs.map((map) {
      return Atom.fromMap(json.decode(map));
    }).toList();

    receivingMessages(messages);
  }

  List<Atom> getDiffMessagesFromIncomingMerkleTrie(Map merkleMap) {
    final clientMerkle = MerkleTrie.fromMap(merkleMap, 36);
    final tsString = trie.diff(clientMerkle);

    if (tsString != null) {
      // minutes to ms
      final ts = int.parse(tsString, radix: 36) * 60000;
      // minutes to logicalTime

      final messagestoSend = _db.getMessagesSince(ts << 16);
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
