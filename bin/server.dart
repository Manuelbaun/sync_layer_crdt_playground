import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;
import 'dart:typed_data';
import 'package:sync_layer/sync/sync_imple.dart';

import 'nodeOrm.dart';

void main() async {
  final server = await HttpServer.bind('0.0.0.0', 8000);

  print("listen to 0.0.0.0:8000");
  final wsSet = <WebSocket>{};
  final node = NodeORM('server');

  node.todo.updatedEntryStream.listen((todos) {
    todos.forEach(print);
  });

  // node.syn.atomStream.listen(print);

  // node.syn.onChanges.listen((changeSet) {
  //   // todo: quick and dirty
  //   for (var change in changeSet) {
  //     final todo = node.todo.read(change.rowId);
  //     print(todo);
  //   }
  // });

  server.listen((HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket ws) {
      wsSet.add(ws);

      print(ws);

      ws.listen(
        (rawData) {
          // print(rawData);
          if (rawData is Uint8List) {
            final type = (rawData as Uint8List)[0];
            final data = rawData.sublist(1);

            if (type == MessageType.UPDATE.index) {
              node.applyUpdate(data);

              // broadcast to all others
              for (final _ws in wsSet) {
                print('${_ws.hashCode} - ${ws.hashCode}');

                if (_ws != ws && _ws.readyState == WebSocket.open) {
                  _ws.add(rawData);
                }
              }
            }

            // compare merkle trie and send diffs
            if (type == MessageType.STATE.index) {
              ws.add(node.getState()); // send localstate
              ws.add(node.getDiff(data)); // send all diffs
            }
          } else {
            print('not the protocol');
          }
        },
        onDone: () => print('[+]Done :)'),
        onError: (err) => print('[!]Error -- ${err.toString()}'),
        cancelOnError: true,
      );
    }, onError: (err) => print('[!]Error -- ${err.toString()}'));
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));
}
