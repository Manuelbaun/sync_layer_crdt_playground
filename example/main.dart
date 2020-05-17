import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:sync_layer/index.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';

import 'dao.dart';

/// --------------------------------------------------------------
/// --------------------------------------------------------------
/// --------------------------------------------------------------
void main(List<String> arguments) {
  // create protocol class
  final rand = Random();
  final nodeID = rand.nextInt(999999);
  final SyncLayer syn = SyncLayerImpl(nodeID);
  final protocol = SyncLayerProtocol(syn);

  // create first container by type
  final todoFactory = (Accessor acc, String id) => Todo(acc, id: id);
  final assigneeFactory = (Accessor acc, String id) => Assignee(acc, id: id);

  final daoTodo = syn.registerObjectType<Todo>('todos', todoFactory);
  final daoAss = syn.registerObjectType<Assignee>('assignee', assigneeFactory);

  daoTodo.changeStream.listen((objs) {
    objs.forEach((o) => logger.info(o.toString()));
  });

  daoAss.changeStream.listen((objs) => objs.forEach((o) => logger.info(o.toString())));

  /// Setup connection
  WebSocket.connect('ws://localhost:8000').then((WebSocket ws) {
    if (ws?.readyState == WebSocket.open) {
      // setup send channel
      protocol.registerConnection(ws);
    } else {
      logger.warning('[!]Connection Denied');
    }
    // in case, if server is not running now
  }, onError: (err) => logger.error(err.toString()));

  // apply changes
  final tt = daoTodo.create();
  final id = tt.id;
  tt.title = 'init Title';

  Timer.periodic(Duration(seconds: 2), (tt) {
    final t = daoTodo.read(id);

    if (t != null) {
      syn.transaction(() {
        t.title = 'hallo $nodeID ${tt.tick}';
        t.title = 'hallo $nodeID ${tt.tick}-2';

        if (t.assignee == null) {
          final a = daoAss.create();

          a.firstName = 'Hans';
          a.lastName = 'Peter';
          a.age = 25;
          a.age = 26;
          a.age = 27;
          a.firstName = 'Doch Ben';
          a.age = 25;
          a.age = 26;
          a.age = 27;
          a.firstName = 'Doch Ben';
          a.age = 25;
          a.age = 26;
          a.age = 27;
          a.firstName = 'Doch Ben';
          a.age = 25;
          a.age = 26;
          a.age = 27;
          a.firstName = 'Doch Ben';
          a.age = 25;
          a.age = 26;
          a.age = 27;
          a.firstName = 'Doch Ben';
          a.age = 25;
          a.age = 26;
          a.age = 27;
          a.firstName = 'Doch Ben';
          a.todo = t;

          t.assignee = a;
          // circular ref!
        }
      });

      Timer(Duration(seconds: 2), () {
        daoTodo.delete(id);
        // finish program
        tt.cancel();
      });
    }
  });
}
