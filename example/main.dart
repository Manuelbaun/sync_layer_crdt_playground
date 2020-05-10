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
  final daoTodo = syn.registerObjectType<Todo2>('todos', (c, id) => Todo2(c, id: id));
  final daoAss = syn.registerObjectType<Assignee>('assignee', (c, id) => Assignee(c, id: id));

  daoTodo.changeStream.listen((objs) => objs.forEach(print));
  daoAss.changeStream.listen((objs) => objs.forEach(print));

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
  daoTodo.update('cka1jh04v000csa3aufnz114h', 'title', 'init Title');

  Timer.periodic(Duration(seconds: 2), (tt) {
    final t = daoTodo.getEntry('cka1jh04v000csa3aufnz114h');
    if (t != null) {
      t.title = 'hallo $nodeID ${tt.tick}';
    }

    if (t.assignee == null) {
      t.assignee = daoAss.create(null);
      t.assignee.firstName = 'Hans';
      t.assignee.lastName = 'Peter';
      t.assignee.age = 25;
      
      // circular ref!
      t.assignee.todo = t;
    }
  });
}
