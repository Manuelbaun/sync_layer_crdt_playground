import 'dart:convert';
import 'dart:io' show WebSocket;
import 'dart:async' show Timer;
import 'dart:math';

import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/sync/sync_imple.dart';






void main() {
  WebSocket.connect('ws://localhost:8000').then((WebSocket ws) {

    var localNode = Random().nextInt(1000).toString();
    final syn = SyncLayerImpl(localNode);

    syn.db.createTable('Todo');
    syn.db.createTable('Assignee');

    syn.onChange = (rows, tables) {
      rows.forEach((row) => print(row.prettyJson()));
    };

    /// send via network!
    syn.onSend = (List<Atom> messages) {
      ws.add(json.encode({'msg': messages}));
    };

    // our websocket server runs on ws://localhost:8000
    if (ws?.readyState == WebSocket.open) {
      // as soon as websocket is connected and ready for use, we can start talking to other end

      // First send local merkle tree and get diffs back
      final str = json.encode({'merkle': syn.trie.toJson()});
      ws.add(str);

      // create first object TODO
      final todoId = localNode;
      syn.sendMessages([
        syn.createAtom('todo', todoId, 'title', 'My todo of $localNode'),
        syn.createAtom('todo', todoId, 'lastUpdate', DateTime.now().toIso8601String()),
        syn.createAtom('todo', todoId, 'done', false),
      ]);

      var done = false;
      // update local state and send to server
      Timer.periodic(Duration(milliseconds: 1000), (t) {
        done = !done;
        syn.sendMessages([
          syn.createAtom('todo', todoId, 'done', done),
          syn.createAtom('todo', todoId, 'lastUpdate', DateTime.now().toIso8601String())
        ]);
      });

      ws.listen(
        (data) {
          // print('<== Recv : ${(data as String).length}');

          final jsonMsg = json.decode(data);
          final merkleMerge = jsonMsg['merkle-merge'];
          final messages = jsonMsg['msg'];

          if (merkleMerge != null) {
            final msgLength = jsonMsg['length'];
            print('receive messages from Merkle diffing: $msgLength');
          }

          if (messages != null) {
            syn.onIncomingJsonMsg(messages);
          }
        },
        onDone: () => print('[+]Done :)'),
        onError: (err) => print('[!]Error -- ${err.toString()}'),
        cancelOnError: true,
      );
    } else {
      print('[!]Connection Denied');
    }
    // in case, if serer is not running now
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));
}
