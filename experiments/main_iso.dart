// the entry point for the isolate
import 'dart:isolate';

import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/utils/measure.dart';

import 'dao.dart';

void remoteNode(SendPort sendPort) async {
  // Open the ReceivePort for incoming messages.

  var port = ReceivePort();
  final remote = SyncDao(123542);

  // Notify any other isolates what port this isolate listens to.
  sendPort.send(port.sendPort);

  await for (var msg in port) {
    String id;

    var us = measureExecution('decode and apply remote', () {
      final atoms = msgpackDecode(msg);
      final aa = List<AtomBase>.from(atoms);
      id = aa[0].objectId;
      remote.syn.applyRemoteAtoms(aa);
    });

    // if (data == "bar") port.close();
  }
}

void main2() async {
  var receivePort = ReceivePort();
  await Isolate.spawn(remoteNode, receivePort.sendPort);

  // The 'echo' isolate sends it's SendPort as the first message
  var sendPort = await receivePort.first;

  var msg = await sendReceive(sendPort, "foo");
  print('received $msg');
  msg = await sendReceive(sendPort, "bar");
  print('received $msg');

  // final threadPorts = <SendPort>[];

  // var receivePort = ReceivePort();
  // await Isolate.spawn(remoteNode, receivePort.sendPort);

  // // The 'echo' isolate sends it's SendPort as the first message
  // SendPort sendPort = await receivePort.first;
  // threadPorts.add(sendPort);

  // local.syn.atomStream.listen((a) {
  //   final b = msgpackEncode(a);

  //   threadPorts.forEach((s) => s.send(b));
  // });
}

/// sends a message on a port, receives the response,
/// and returns the message
Future sendReceive(SendPort port, msg) {
  final response = ReceivePort();
  port.send([msg, response.sendPort]);
  return response.first;
}
