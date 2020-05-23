import 'dart:math';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

import '../utils/fake_db.dart';

void main() {
  final db = FakeDbForIds();
  final hlcs = db.generate(DateTime(2020, 1), DateTime(2020, 4), 1000);

  test('Merging two merkle tries', () {
    print('All ${hlcs.length}');

    var localMap;

    var remoteMap;
    final rand = Random(0);
    final localHlcs = hlcs;
    final remoteHlcs = hlcs.where((t) => rand.nextBool()).toList();

    final remoteMins = remoteHlcs.map((h) => (h.ts as HybridLogicalClock).minutes).toList();
    final diff = db.filterBySetOfMinutes(remoteMins);

    for (var radix = 36; radix <= 36; radix++) {
      final localTree = MerkleTrie(radix);
      final remoteTree = MerkleTrie(radix);

      print('=== Radix: $radix '.padRight(50, '='));

      var mskip;
      measureExecution('build local tree', () {
        mskip = localTree.build(localHlcs);
      });

      var mskip_;
      measureExecution('build remote tree', () {
        mskip_ = remoteTree.build(remoteHlcs);
      });

      final rl = localTree.getDifferences(remoteTree);

      print(rl);
      final minsL = rl.local.map((key) => int.parse(key, radix: radix)).toList();
      final minsR = rl.remote.map((key) => int.parse(key, radix: radix)).toList();
      final diff = db.filterBySetOfMinutes(minsR);

      print(diff);
    }
  });
}




