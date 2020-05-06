import 'dart:math';
import 'dart:typed_data';

import 'package:lzma/lzma.dart';
import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/basic/hlc.dart';
import 'package:sync_layer/crdts/atom.binar.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:faker/faker.dart';

void main() {
  List send = [];
  List recv = [];
  final rand = Random();

  List<String> bytes = [];
  for (var i = 0; i < 1000; i++) {
    final ts = Hlc(faker.date.dateTime(minYear: 2000, maxYear: 2020).millisecondsSinceEpoch);
    final node = rand.nextInt(328498234);
    final type = rand.nextInt(2000);
    final key = rand.nextInt(2000);
    final value = faker.lorem.words(30).join(' ');

    final a = AtomBinary(ts.logicalTime, node, type, newCuid(), key, value);
    send.add(a);
  }
  var msg;
  var compressed;
  measureExecution("compress data", () {
    for (var msg in send) {
      final b = msg.toByte();
      final ss = String.fromCharCodes(b);
      bytes.add(ss);
    }
    msg = bytes.join(';\0');
    compressed = lzma.encode(msg.codeUnits);
  });

  var decompressed;
  var strr;

  measureExecution("decompress data", () {
    decompressed = lzma.decode(compressed);
    strr = String.fromCharCodes(decompressed).split(';\0');

    for (var msg in strr) {
      var b = Uint8List.fromList(msg.codeUnits);
      final a = AtomBinary.from(b);
      recv.add(a);
    }
  });

  print(msg.length);
  print(compressed.length);
  print(compressed.length / msg.length);
  print(decompressed.length);

  for (var i = 0; i < send.length; i++) {
    final a = send[i];
    final b = recv[i];

    // print(a == b);
  }

  // send.forEach(print);
  // recv.forEach(print);
}

// final ts = DateTime(2000).millisecondsSinceEpoch;
// final id = newCuid();
// final value = 'Hello world';
// final nodeID = 12345667;
// final type = 1;
// final key = 1;

// void measureAtomBinar1() {
//   print('-------------------');
//   print('measureAtomBinar1');
//   AtomBinary atom;
//   AtomBinary atomCopy;
//   Uint8List buff;

//   final val = value;
//   measureExecution('To Atom', () {
//     atom = AtomBinary(ts, nodeID, type, id, key, val);
//   });

//   measureExecution('toBytes', () {
//     buff = atom.toByte();
//   });

//   measureExecution('from bytes', () {
//     atomCopy = AtomBinary.from(buff);
//   });

//   print(atom);
//   print(atomCopy);
//   print(buff.length);

//   measureExecution('Complete', () {
//     atom = AtomBinary(ts, nodeID, type, id, key, val);
//     buff = atom.toByte();
//     atomCopy = AtomBinary.from(buff);
//   });
// }
