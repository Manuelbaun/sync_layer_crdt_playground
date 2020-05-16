import 'dart:math';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

import '../utils/fake_db.dart';

void main() {
  final db = FakeDbForIds();
  final hlcs = db.getHlcs();

  test('Merging two merkle tries', () {
    print('All ${hlcs.length}');
    var localMap;
    var remoteMap;
    final rand = Random(0);
    final localHlcs = hlcs;
    final remoteHlcs = hlcs.sublist(0, hlcs.length - 10);

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

      var mergeTry = 1;
      while (remoteTree.hash != localTree.hash) {
        if ((mergeTry % 100) == 0) break;

        print('=== Merge try ${mergeTry++} '.padRight(50, '='));

        String diffs;
        measureExecution('Diffing local/remote', () {
          diffs = localTree.diff(remoteTree);
        });

        var ts = int.parse(diffs, radix: radix);

        var localdiffs = <Id>[];
        measureExecution('find local diffs', () {
          localdiffs = db.filterAfterTime(ts);
        });

        var remotediffs = <Id>[];
        measureExecution('find remote diffs', () {
          remotediffs = db.filterAfterTime(ts);
        });

        MergeSkip mskipLocal;
        measureExecution('Merge remote into local', () {
          mskipLocal = localTree.build(localdiffs);
        });
        print('=> Merge ${mskipLocal.merged.length} : skipped ${mskipLocal.skipped.length}');

        MergeSkip mskipRemote;
        measureExecution('Merge local into remote', () {
          mskipRemote = remoteTree.build(remotediffs);
        });

        print('=> Merge ${mskipRemote.merged.length} : skipped ${mskipRemote.skipped.length}');
      }

      print('=== Equal: ${localTree.hash == remoteTree.hash} '.padRight(50, '='));

      final diffs = localTree.diff(remoteTree);

      expect(diffs == null, isTrue);
      expect(localTree.hash == remoteTree.hash, isTrue);

      KeysLR rl = localTree.getDifferences(remoteTree);

      expect(rl.local.length, 0);
      expect(rl.remote.length, 0);

      KeysLR rl2 = remoteTree.getDifferences(localTree);
      expect(rl2.local.length, 0);
      expect(rl2.remote.length, 0);
      print(rl);

      measureExecution('Local toMap', () {
        localMap = localTree.toMap();
      });

      var trie;

      measureExecution('from json local tree', () {
        trie = MerkleTrie.fromMap(localMap, radix);
      });
    }
  });
}
