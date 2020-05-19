import 'dart:async';

import 'package:sync_layer/crdts/causal_tree/index.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/abstract/syncable_base.dart';

import 'package:sync_layer/sync/syncable_causal_tree.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/logical_clock.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

import '../utils/fake_accessor.dart';

class FakeNetwork {
  final map = <int, SyncableBase>{};

  void register(SyncableCausalTree obj) {
    if (!map.containsKey(obj.proxy.site)) {
      map[obj.proxy.site] = obj;
    }
  }

  void add(AtomBase a) {
    final atomBytes = msgpackEncode(a);
    print(atomBytes.length);
    final atom = msgpackDecode(atomBytes);
    print(atom == a);

    for (var obj in map.entries) {
      if (a.id.site != obj.key) obj.value.applyAtom(atom);
    }
  }
}

void main() {
  final network = FakeNetwork();
  final acc1 = FakeAccessorHLC('CausalTree'.hashCode, 0xa, network.add);
  final acc2 = FakeAccessorHLC('CausalTree'.hashCode, 0xb, network.add);

  final list1 = SyncableCausalTree(acc1, 'line1');
  final list2 = SyncableCausalTree(acc2, 'line1');

  network.register(list1);
  network.register(list2);

  list1.add('h');
  list1.add('e');
  list1.add('l');
  list1.add('o');

  list1.insert(3, 'l');
  print(list1.values);
  print(list2.values);

  print('hallo'.hashCode);
  print('hallo'.hashCode);

  test('is equal', () {
    expect(list1.values.join(''), 'hello');
    expect(list2.values.join(''), 'hello');
  });
}

void causalTree() {
  CausalTree<String> a;
  CausalTree<String> b;

  setUp(() {
    a = CausalTree<String>(1);
    b = CausalTree<String>(2);
  });

  test('Merge CTRLDEL Merge', () {
    final unsubscribeA = a.stream.listen((atom) {
      b.mergeRemoteAtoms([atom]);
    });

    final unsubscribeB = b.stream.listen((atom) {
      a.mergeRemoteAtoms([atom]);
    });
    measureExecution('add and merge', () {
      final a1 = a.insert(null, 'C');
      final a2 = a.insert(a1, 'M');
      final a3 = a.insert(a2, 'D');

      a.localClock = LogicalClock(5);
      final a6 = a.delete(a2);
      final a7 = a.delete(a3);
      final a8 = a.insert(a1, 'T');
      final a9 = a.insert(a8, 'R');
      final aA = a.insert(a9, 'L');

      // ------------- B
      b.localClock = LogicalClock(5);
      final b6 = b.insert(a3, 'D');
      final b7 = b.insert(b6, 'E');
      final b8 = b.insert(b7, 'L');
    });

    measureExecution('Tree print time: ', () {
      final str = a.toString();
    });

    print('$a - ${a.length}: ${a.deletedLength}');
    print('$b - ${b.length}: ${b.deletedLength}');

    var index = 0;
    final abEqual = a.sequence.every((a) => a == b.sequence[index++]);

    expect(a.toString(), 'CTRLDEL');
    expect(b.toString(), 'CTRLDEL');

    expect(abEqual, true);
  });

  test('Fail merge', () {
    // final unsubscribeA = a.stream.listen((atom) {
    //   b.mergeRemoteAtoms([atom]);
    // });

    // final unsubscribeB = b.stream.listen((atom) {
    //   a.mergeRemoteAtoms([atom]);
    // });

    final all = <CausalEntry<String>>[];
    all.add(a.push('H'));
    all.add(a.push('A'));
    all.add(a.push('L'));
    all.add(a.push(' '));

    b.mergeRemoteAtoms(all);
    print(a.toString());
    print(b.toString());
    print('................');
    all.add(a.push('W'));
    all.add(a.push('O'));
    all.add(a.push('R'));
    all.add(a.push('L'));
    all.add(a.push('D'));

    /// correction
    all.add(a.insert(all[2], 'O'));
    print(a.toString());
    print(b.toString());
    // all.add();

    a.mergeRemoteAtoms([b.insert(all[2], 'L')]);

    b.mergeRemoteAtoms(a.sequence);
    print(a.toString());
    print(b.toString());
  });
}
