import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;
import 'dart:typed_data';

import 'package:sync_layer/sync2/impl/index.dart';
import 'package:sync_layer/sync2/sync_layer_protocol.dart';

import 'dao.dart';

void main() async {
  final server = await HttpServer.bind('0.0.0.0', 8000);

  print('listen to 0.0.0.0:8000');

  final syn = SyncLayerImpl('server');
  final daoTodo = syn.registerObjectType<Todo2>('todos', (c) => Todo2(c));
  final protocol = SyncLayerProtocol(syn);

  server.listen((HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket ws) {
      protocol.registerConnection(ws);
      // wsSet.add(ws);

      // ws.listen(
      //   (rawData) {
      //     if (rawData is Uint8List) {
      //       protocol.receiveBuffer(rawData, ws);

      //       if (rawData[0] == MessageEnum.ATOMS.index) {
      //         // broadcast to all others
      //         for (final _ws in wsSet) {
      //           if (_ws != ws && _ws.readyState == WebSocket.open) {
      //             print('${_ws.hashCode} - ${ws.hashCode}');
      //             _ws.add(rawData);
      //           }
      //         }
      //       }
      //     } else {
      //       print('not the protocol');
      //     }
      //   },
      //   onDone: () => print('[+]Done :)'),
      //   onError: (err) => print('[!]Error -- ${err.toString()}'),
      //   cancelOnError: true,
      // );
    }, onError: (err) => print('[!]Error -- ${err.toString()}'));
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));
}
