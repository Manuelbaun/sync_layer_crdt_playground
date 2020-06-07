import 'dart:io';
import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:sync_layer/basic/merkle_tire.dart';
import 'package:sync_layer/basic/merkle_tire_2.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';
import '../utils/fake_db.dart';

void testTrie(dynamic trie, List<Id> hlcs) {
  measureExecution('trie', () {
    trie.build(hlcs);
  });

  var map;
  measureExecution('mapping', () {
    map = serialize(trie.toMap());
  });

  Uint8List msg_s;
  measureExecution('ser', () {
    msg_s = serialize(map);
  });
  var en;
  measureExecution('lzip', () {
    en = zlib.encode(msg_s);
  });

  print(msg_s.length);
  print(en.length);
}

void main() {
  final d = DateTime(2020).millisecondsSinceEpoch & 0xffffffffffff; // 6 bytes
  final min = (d / 60000).floor();
  final min2 = d >> 16;

  final s1 = d.toRadixString(36);
  final s2 = min.toRadixString(36);
  final s3 = min2.toRadixString(36);

  print(s1);
  print(s2);
  print(s3);

  final db = FakeDbForIds();
  final hlcs = db.generate(DateTime(2020), DateTime(2030, 2), 10000);

  final trie1 = MerkleTrie2();
  final trie2 = MerkleTrie();

  // testTrie(trie1, hlcs);
  // testTrie(trie2, hlcs);
}
