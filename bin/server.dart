import 'dart:convert';
import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;

import 'package:sync_layer/sync/sync_imple.dart';

void main() {
  HttpServer.bind('localhost', 8000).then((HttpServer server) {
    print('[+]WebSocket listening at -- ws://localhost:8000/');
    final wsSet = <WebSocket>{};

    final syn = SyncLayerImpl('Server');
    syn.db.createTable('todo');

    server.listen((HttpRequest request) {
      WebSocketTransformer.upgrade(request).then((WebSocket ws) {
        wsSet.add(ws);

        ws.listen(
          (data) {
            final jsonMsg = json.decode(data);
            if (jsonMsg['msg'] != null) {
              syn.onIncomingJsonMsg(jsonMsg['msg']);
            }

            // compare merkle trie and send diffs
            if (jsonMsg['merkle'] != null) {
              final Map merkleMap = json.decode(jsonMsg['merkle']);
              final messages = syn.getDiffMessagesFromIncomingMerkleTrie(merkleMap);
              if (messages.isNotEmpty) {
                messages.forEach(print);
                final send = json.encode({'msg': messages});
                ws.add(send);
              }
            }

            // broadcast to all others
            for (final _ws in wsSet) {
              if (_ws != ws && _ws.readyState == WebSocket.open) _ws.add(data);
            }
          },
          onDone: () => print('[+]Done :)'),
          onError: (err) => print('[!]Error -- ${err.toString()}'),
          cancelOnError: true,
        );
      }, onError: (err) => print('[!]Error -- ${err.toString()}'));
    }, onError: (err) => print('[!]Error -- ${err.toString()}'));
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));
}
