import 'dart:async';
import 'dart:io';

import 'package:sync_layer/sync2/impl/index.dart';
import 'package:sync_layer/sync2/sync_layer_protocol.dart';

import 'dao.dart';

/// --------------------------------------------------------------
/// --------------------------------------------------------------
/// --------------------------------------------------------------
void main() {
  // create protocol class
  final syn = SyncLayerImpl('local');
  final protocol = SyncLayerProtocol(syn);

  // create first container by type
  final daoTodo = syn.registerObjectType<Todo2>('todos', (c) => Todo2(c));

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

    print('${t.title} , ${t.tompstone}');
  });
}
