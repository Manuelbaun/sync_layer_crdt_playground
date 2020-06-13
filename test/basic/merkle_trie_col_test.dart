import 'dart:io';
import 'dart:math';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

import '../utils/fake_db.dart';

void main() {
  // test1();
  test2();
}

void test2() {
  test('Merging two merkle tries', () {
    final newPath = Directory.current.path + '\\' + 'measur';
    final dir = Directory(newPath)..createSync(recursive: true);
    final path = dir.path + '\\';

    final file = File(
      path + 'merkle_trie_grow-${DateTime.now().millisecondsSinceEpoch}.csv',
    ).openWrite(mode: FileMode.append);

    file.write('radix;id[amount];step[min];build_tree[ms];size[bytes]\n');

    MerkleTrie tree;

    var max = 100000;
    var step = 10;
    final amount = 10000;
    final from = DateTime(2020, 1).millisecondsSinceEpoch;

    for (var min = 0; min < max; min += step) {
      // generate timestamps
      final ids = List.generate(amount, (int d) {
        final mins = d * min;
        final ms = from + mins * 60000;
        final hlc = HybridLogicalClock(ms);
        return Id(hlc, 0x7fffffff);
      });

      var radix = 36;
      // for (var radix = 36; radix <= 36; radix++) {
      tree = MerkleTrie(radix);
      var us1 = measureExecution('build local tree', () {
        tree.build(ids);
      }, skipLog: true);

      final b = msgpackEncode(tree.toMap());

      if (min % 1000 == 0) {
        print('$radix;$amount;$min;${us1 / 1000}ms;${b.length};');
      }
      file.write('$radix;$amount;$min;${us1 / 1000};${b.length};\n');
      // }
    }

    // print(tree.toJsonPretty());

    file.close();
  });
}

void test1() {
  test('Merging two merkle tries', () {
    final db = FakeDbForIds();
    final amount = 100000;
    final from = DateTime(2020, 1);
    final to = DateTime(2030, 1);
    final minMs = from.millisecondsSinceEpoch;
    final maxMs = to.millisecondsSinceEpoch;
    final step = maxMs - minMs;
    final hlcs = db.generate(from, to, amount);
    print('All ${hlcs.length}');

    final newPath = Directory.current.path + '\\' + 'measur';
    final dir = Directory(newPath)..createSync(recursive: true);
    final path = dir.path + '\\';

    final file = File(path + 'merkle_trie_insert_size_$amount-$step-${DateTime.now().millisecondsSinceEpoch}.csv')
        .openWrite(mode: FileMode.append);

    file.write('ts[amount];from[date ms];to[date ms]; step[ms];\n');
    file.write('$amount;${from.millisecondsSinceEpoch};${to.millisecondsSinceEpoch}; $step;\n\n');

    file.write('radix;build_tree[ms];size[bytes];\n');

    var localMap;

    var remoteMap;
    final rand = Random(0);
    final localHlcs = hlcs;
    final remoteHlcs = hlcs.where((t) => rand.nextBool()).toList();

    final remoteMins = remoteHlcs.map((h) => (h.ts as HybridLogicalClock).minutes).toList();
    final diff = db.filterBySetOfMinutes(remoteMins);

    for (var radix = 3; radix <= 36; radix++) {
      final localTree = MerkleTrie(radix);
      final remoteTree = MerkleTrie(radix);

      print('=== Radix: $radix '.padRight(50, '='));

      var mskip;
      int us1 = measureExecution('build local tree', () {
        mskip = localTree.build(localHlcs);
      });

      var mskip_;
      int us2 = measureExecution('build remote tree', () {
        mskip_ = remoteTree.build(remoteHlcs);
      });

      // final rl = localTree.getDifferences(remoteTree);

      // final minsL = rl.local.map((key) => int.parse(key, radix: radix)).toList();
      // final minsR = rl.remote.map((key) => int.parse(key, radix: radix)).toList();
      // final diff = db.filterBySetOfMinutes(minsR);

      final b = msgpackEncode(localTree.toMap());
      print('Tree serialized: ${b.length}');
      // file.write('radix;build_local[ms];build_remote[ms];size[bytes]');
      file.write('$radix;${us1 / 1000};${b.length};\n');
    }

    file.close();
  });
}
