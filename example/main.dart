import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:sync_layer/sync2/impl/index.dart';
import 'package:sync_layer/sync2/sync_layer_protocol.dart';

import 'dao.dart';

/// --------------------------------------------------------------
/// --------------------------------------------------------------
/// --------------------------------------------------------------
void main(List<String> arguments) {
  print(arguments);
  // create protocol class
  final rand = Random();
  final nodeID = arguments.isNotEmpty ? arguments.first : rand.nextInt(999999).toString();
  final syn = SyncLayerImpl(nodeID);
  final protocol = SyncLayerProtocol(syn);

  // create first container by type
  final daoTodo = syn.registerObjectType<Todo2>('todos', (c) => Todo2(c));

  // daoTodo.changeStream.listen((objs) {
  //   objs.forEach(print);
  // });

  /// Setup connection
  WebSocket.connect('ws://localhost:8000').then((WebSocket ws) {
    if (ws?.readyState == WebSocket.open) {
      // setup send channel
      protocol.registerConnection(ws);
    } else {
      print('[!]Connection Denied');
    }
    // in case, if server is not running now
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));

  // apply changes
  Timer.periodic(Duration(seconds: 2), (tt) {
    final t = daoTodo.create();
    t.title = 'hallo ${tt.tick}';
  });
}
