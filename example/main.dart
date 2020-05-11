import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:sync_layer/sync2/impl/index.dart';
import 'package:sync_layer/sync2/sync_layer_protocol.dart';

import 'dao.dart';

void printObj(o) {
  print('Object changed: $o');
}

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

  daoTodo.changeStream.listen((objs) {
    objs.forEach(printObj);
    print(daoTodo.length);
  });

  daoAss.changeStream.listen((objs) => objs.forEach(printObj));

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
  final id = 'cka1jh04v000csa3aufnz114h';
  final tt = daoTodo.create(id);
  tt.title = 'init Title';

  Timer.periodic(Duration(seconds: 2), (tt) {
    final t = daoTodo.read(id);

    if (t != null) {
      syn.transaction(() {
        t.title = 'hallo $nodeID ${tt.tick}';

        if (t.assignee == null) {
          final a = daoAss.create();
          a.firstName = 'Hans';
          a.lastName = 'Peter';
          a.age = 25;
          // a.todo = t;

          t.assignee = a;
          // circular ref!
        }
      });
      
      Timer(Duration(seconds: 2), () {
        daoTodo.delete('cka1jh04v000csa3aufnz114h');
        // finish program
        tt.cancel();
      });
    }
  });
}
