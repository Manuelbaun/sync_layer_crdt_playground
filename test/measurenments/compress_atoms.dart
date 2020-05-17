import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/id_atom.dart';

import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/utils/measure.dart';

final r1 = Random(1111);
final r2 = Random(2222);
final r3 = Random(3333);
final r4 = Random(4444);
final r5 = Random(5555);

int getType() => r1.nextInt(20);
int getKey() => r2.nextInt(20);
int getSiteId() => r3.nextBool() ? 1111 : 2222;
String getObjectID() => r4.nextInt(20).toRadixString(3);

final base = DateTime(2020, 4, 1);
final min = base.millisecondsSinceEpoch;
final max = base.millisecondsSinceEpoch + 1000;
int getMS() => min + r5.nextInt(max - min);

void g_zipping(List<Atom> atoms) {
  Uint8List encoded;
  List<int> zipped;
  Uint8List unzipped;

  measureExecution('gzip pack', () {
    encoded = msgpackEncode(atoms);
    zipped = gzip.encode(encoded);
  });

  var decoded;
  measureExecution('gzip unpack', () {
    unzipped = gzip.decode(zipped);
    decoded = msgpackDecode(unzipped);
  });

  print(encoded.length);
  print(zipped.length);
  print(unzipped.length);
  // print(decoded);
}

void l_zipping(List<Atom> atoms) {
  Uint8List encoded;
  List<int> zipped;
  Uint8List unzipped;

  measureExecution('zlib pack', () {
    encoded = msgpackEncode(atoms);
    zipped = zlib.encode(encoded);
  });

  var decoded;
  measureExecution('zlib unpack', () {
    unzipped = zlib.decode(zipped);
    decoded = msgpackDecode(unzipped);
  });

  print(encoded.length);
  print(zipped.length);
  print(unzipped.length);
  // print(decoded);
}

void main() {
  final atoms = <Atom>[];

  for (var i = 0; i < 10; i++) {
    final a = Atom<SyncableEntry>(
      AtomId(HybridLogicalClock(0, 1), getSiteId()),
      getType(),
      getObjectID(),
      SyncableEntry(getKey(), 'test  $i'),
    );

    atoms.add(a);
  }

  g_zipping(atoms);
  l_zipping(atoms);
}
