import 'dart:math';
import 'dart:typed_data';

import 'package:lzma/lzma.dart';
import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/basic/hlc.dart';
import 'package:sync_layer/crdts/atom.binar.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:faker/faker.dart';

void main() {
  final rand = Random();
  final sendAtoms = <AtomBinary>[];
  final recvAtoms = <AtomBinary>[];

  final bytes = <String>[];
  for (var i = 0; i < 1000; i++) {
    final ts = Hlc(faker.date.dateTime(minYear: 2000, maxYear: 2020).millisecondsSinceEpoch);
    final node = rand.nextInt(328498234);
    final type = rand.nextInt(2000);
    final key = rand.nextInt(2000);
    final value = faker.lorem.words(30).join(' ');

    final a = AtomBinary(ts.logicalTime, node, type, newCuid(), key, value);
    sendAtoms.add(a);
  }

  var compressed;
  var msg;
  measureExecution("compress data", () {
    for (var atom in sendAtoms) {
      final b = atom.toByte();
      bytes.add(String.fromCharCodes(b));
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
      recvAtoms.add(a);
    }
  });

  print(msg.length);
  print(compressed.length);
  print(compressed.length / msg.length);
  print(decompressed.length);

  for (var i = 0; i < sendAtoms.length; i++) {
    final a = sendAtoms[i];
    final b = recvAtoms[i];

    // print(a == b);
  }

  // send.forEach(print);
  // recv.forEach(print);
}
