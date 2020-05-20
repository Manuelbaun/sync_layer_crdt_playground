import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:sync_layer/logger/index.dart';
import 'dao.dart';

/// --------------------------------------------------------------
/// --------------------------------------------------------------
/// --------------------------------------------------------------
void main(List<String> arguments) {
  // create protocol class
  final rand = Random();
  final nodeID = rand.nextInt(999999);
  final dao = SyncDao(nodeID);

  final list1 = dao.syncArray.create();
  list1.push('Hello world');

  final text = dao.syncArray.create();
  final title = faker.job.title();

  text.transact((self) {
    for (var i = 0; i < title.length; i++) {
      self.push(title[i]);
    }
  });

  /// Setup connection
  WebSocket.connect('ws://localhost:8000').then((WebSocket ws) {
    if (ws?.readyState == WebSocket.open) {
      // setup send channel
      dao.protocol.registerConnection(ws);
    } else {
      logger.warning('[!]Connection Denied');
    }
    // in case, if server is not running now
  }, onError: (err) => logger.error(err.toString()));

  // apply changes
  final tt = dao.todos.create();
  final id = tt.id;
  // tt.title = 'init Title';

  Timer.periodic(Duration(seconds: 2), (tt) {
    final t = dao.todos.read(id);

    if (t != null) {
      dao.syn.transaction(() {
        // t.title = 'hallo $nodeID ${tt.tick}';
        // t.title = 'hallo $nodeID ${tt.tick}-2';

        if (t.assignee == null) {
          final a = dao.assignees.create();

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

          // circular ref!
          t.assignee = a;
        }
      });

      Timer(Duration(seconds: 2), () {
        dao.todos.delete(id);
        // finish program
        tt.cancel();
      });
    }
  });
}
