import 'dart:async';
import 'dart:io' show WebSocket;
import 'dart:typed_data';

import 'package:faker/faker.dart';
import 'package:sync_layer/sync/sync_imple.dart';

import 'nodeOrm.dart';

// zip and upzip is network stuff!
// final d2 = lzma.encode(diff21);
// final enD1 = lzma.decode(d1);

void main2() {}

void main() {
  final name = faker.person.firstName();
  final node = NodeORM(name);

  print('Client on $name');

  // init first todo
  node.todo.create('call Saul', status: true);

  node.todo.updatedEntryStream.listen((todos) {
    // print("length ${todos.length}");
    todos.forEach(print);
  });

  // for (var todo in node.todo.items.values) {
  //   print(todo);
  // }

  // node.syn.atomStream.listen((atom) {
  //   print('..........');
  //   print(atom);
  //   print(node.db.allMessages.length);
  // });

  // node.syn.onChanges.listen((changeSet) {
  //   for (var change in changeSet) {
  //     // todo: quick and dirty
  //     final todo = node.todo.read(change.rowId);
  //     print(todo);
  //   }
  // });

  Timer.periodic(Duration(seconds: 3), (t) {
    final todo = node.todo.create('call Saul ${t.tick}');

    Timer(Duration(seconds: 1), () {
      todo.status = true;
    });
  });

  WebSocket.connect('ws://localhost:8000').then((WebSocket ws) {
    /// send via network!

    // our websocket server runs on ws://localhost:8000
    if (ws?.readyState == WebSocket.open) {
      // as soon as websocket is connected and ready for use, we can start talking to other end

      // First send local merkle tree and get diffs back
      ws.add(node.getState());

      // send all updates to the server ASAP
      node.syn.onUpdates.listen((data) {
        print('Send data to server: ${data.length}');
        ws.add(data);
      });

      ws.listen(
        (rawData) {
          if (rawData is Uint8List) {
            // print('Get data from server ${rawData.length}');
            final type = rawData[0];
            final data = rawData.sublist(1);

            // if localnode receives a state! response with diff atoms
            if (type == MessageType.STATE.index) {
              ws.add(node.getDiff(data));
            } else if (type == MessageType.UPDATE.index) {
              // if localnode recieves an update, apply
              node.applyUpdate(data);
            }
          } else {
            print('unknowing data');
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
