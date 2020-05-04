import 'dart:convert';
import 'dart:io' show WebSocket;
import 'dart:async' show Timer;
import 'dart:math';

import 'package:sync_layer/sync/message.dart';
import 'package:sync_layer/sync/sync_imple.dart';

void main() {
  WebSocket.connect('ws://localhost:8000').then((WebSocket ws) {
    var localNode = Random().nextInt(1000).toString();
    final syn = SyncLayerImpl(localNode);

    syn.db.createTable('todo');
    syn.onSync = (rows) => rows.forEach((row) => print(row.prettyJson()));

    syn.onSend = (List<SyncMessage> messages) {
      final data = {'msg': messages, 'merkle': syn.clock.merkle.toJson()};
      final str = json.encode(data);
      print('==> Send: ${str.length}');
      ws.add(str);
    };

    // our websocket server runs on ws://localhost:8000
    if (ws?.readyState == WebSocket.open) {
      // as soon as websocket is connected and ready for use, we can start talking to other end

      syn.sendMessages([
        syn.createMsg('todo', '123-' + localNode, 'title', 'My First todo'),
        syn.createMsg('todo', '123-' + localNode, 'done', false),
      ]);

      Timer(Duration(seconds: 5), () {
        syn.sendMessages([
          syn.createMsg('todo', '123-' + localNode, 'done', true),
        ]);
      });

      ws.listen(
        (data) {
          print('<== Recv : ${(data as String).length}');

          final jsonMsg = json.decode(data);

          if (jsonMsg['msg'] != null) {
            syn.onIncomingJsonMsg(jsonMsg['msg']);
          }

          if (jsonMsg['merkle'] != null) {
            // print(jsonMsg['merkle']);
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
