import 'package:sync_layer/crdts/causal_tree/index.dart';
import 'package:sync_layer/types/logical_clock.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

void main() {
  group('CausalTree manually: ', mergeTestManually);
  group('CausalTree with onLocalUpdateCallback: ', mergeTestWithCallback);
}

void mergeTestManually() {
  CausalTree<String> a;
  CausalTree<String> b;
  CausalTree<String> c;
  CausalTree<String> d;

  setUp(() {
    a = CausalTree<String>(1);
    b = CausalTree<String>(2);
    c = CausalTree<String>(3);
    d = CausalTree<String>(4);

    measureExecution('add and merge Manually', () {
      final a1 = a.insert(null, 'C');
      final a2 = a.insert(a1, 'M');
      final a3 = a.insert(a2, 'D');

      b.mergeRemoteEntries(a.sequence);
      c.mergeRemoteEntries(a.sequence);
      d.mergeRemoteEntries(a.sequence);

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

      final b9 = b.insert(b8, 'A');
      final bA = b.insert(b9, 'C');
      final bB = b.insert(bA, 'T');

      // ------------- C
      c.localClock = LogicalClock(6);
      final c7 = c.insert(a3, 'A');
      final c8 = c.insert(c7, 'L');
      final c9 = c.insert(c8, 'T');

      // ------------- D
      d.localClock = LogicalClock(10);
      d.mergeRemoteEntries(a.sequence);
      final d10 = d.insert(aA, 'S');
      final d11 = d.insert(d10, 'P');
      final d12 = d.insert(d11, 'A');
      final d13 = d.insert(d12, 'C');
      final d14 = d.insert(d13, 'E');

      /// all changed merge into a
      a.mergeRemoteEntries(b.sequence);
      a.mergeRemoteEntries(c.sequence);
      a.mergeRemoteEntries(d.sequence);

      /// merge new state of a into b, c, d
      b.mergeRemoteEntries(a.sequence);
      c.mergeRemoteEntries(a.sequence);
      d.mergeRemoteEntries(a.sequence);
    });
  });

  test('subscription Merge', () {
    measureExecution('Tree print time: ', () {
      final str = a.value.map((e) => e.data).join('');
    });

    print('$a - ${a.length}: ${a.deletedLength}');
    print('$b - ${b.length}: ${b.deletedLength}');
    print('$c - ${c.length}: ${c.deletedLength}');
    print('$d - ${d.length}: ${d.deletedLength}');

    final sa = a.value.map((e) => e.data).join('');
    final sb = b.value.map((e) => e.data).join('');
    final sc = c.value.map((e) => e.data).join('');
    final sd = d.value.map((e) => e.data).join('');

    /// test if all values are in the same sequence
    expect(sa, 'CTRLSPACEALTDELACT');
    expect(sb, 'CTRLSPACEALTDELACT');
    expect(sc, 'CTRLSPACEALTDELACT');
    expect(sd, 'CTRLSPACEALTDELACT');

    var index = 0;
    final abEqual = a.sequence.every((a) => a == b.sequence[index++]);

    index = 0;
    final acEqual = a.sequence.every((a) => a == c.sequence[index++]);

    index = 0;
    final adEqual = a.sequence.every((a) => a == d.sequence[index++]);

    /// test if all entries are actually in the same sequnce
    expect(abEqual, true);
    expect(acEqual, true);
    expect(adEqual, true);
  });

  group('filter 1 tree', () {
    test('filter by timestamp', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by timestamp', () {
        filteredAtoms = a.filtering(tsMin: LogicalClock(0));
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'CTRLSPACEALTDELACT');
    });

    test('filter by timestamp', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by timestamp', () {
        filteredAtoms = a.filtering(tsMin: LogicalClock(10));
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'LSPACECT');
    });

    test('filter by timestamp', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by timestamp', () {
        filteredAtoms = a.filtering(
          tsMin: LogicalClock(10),
          siteIds: {4},
          semantic: FilterSemantic.AND,
        );
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'SPACE');
    });
    test('filter by one siteid', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by one siteid', () {
        filteredAtoms = a.filtering(siteIds: {2});
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'DELACT');
    });

    test('filter by two siteids', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by two siteids', () {
        filteredAtoms = a.filtering(siteIds: {4, 2});
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'SPACEDELACT');
    });

    test('filter by one siteids and timestamp', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by one siteids and timestamp', () {
        filteredAtoms = a.filtering(
          siteIds: {2},
          tsMin: LogicalClock(6),
          tsMax: LogicalClock(9),
          semantic: FilterSemantic.AND,
        );
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'DEL');
    });
  });

  group('assert test', () {
    test('assert when not filter parameter are provided', () {
      try {
        a.filtering();
      } catch (e) {
        expect(e.message, 'all filter are null, cannot filter by something');
      }
    });
  });
}

void mergeTestWithCallback() {
  CausalTree<String> a;
  CausalTree<String> b;
  CausalTree<String> c;
  CausalTree<String> d;

  setUp(() {
    a = CausalTree<String>(1, onLocalUpdate: (atom) {
      b.mergeRemoteEntries([atom]);
      c.mergeRemoteEntries([atom]);
      d.mergeRemoteEntries([atom]);
    });

    b = CausalTree<String>(2, onLocalUpdate: (atom) {
      a.mergeRemoteEntries([atom]);
      c.mergeRemoteEntries([atom]);
      d.mergeRemoteEntries([atom]);
    });

    c = CausalTree<String>(3, onLocalUpdate: (atom) {
      a.mergeRemoteEntries([atom]);
      b.mergeRemoteEntries([atom]);
      d.mergeRemoteEntries([atom]);
    });

    d = CausalTree<String>(4, onLocalUpdate: (atom) {
      a.mergeRemoteEntries([atom]);
      b.mergeRemoteEntries([atom]);
      c.mergeRemoteEntries([atom]);
    });

    measureExecution('add and merge with callback', () {
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

      final b9 = b.insert(b8, 'A');
      final bA = b.insert(b9, 'C');
      final bB = b.insert(bA, 'T');

      // ------------- C
      c.localClock = LogicalClock(6);
      final c7 = c.insert(a3, 'A');
      final c8 = c.insert(c7, 'L');
      final c9 = c.insert(c8, 'T');

      // ------------- D
      d.localClock = LogicalClock(10);
      // d.mergeRemoteEntries(a.sequence);
      final d10 = d.insert(aA, 'S');
      final d11 = d.insert(d10, 'P');
      final d12 = d.insert(d11, 'A');
      final d13 = d.insert(d12, 'C');
      final d14 = d.insert(d13, 'E');
    });
  });

  test('eqal test', () {
    final astr = a.sequence.map((e) => e.data).join('');
    final bstr = b.sequence.map((e) => e.data).join('');
    final cstr = c.sequence.map((e) => e.data).join('');
    final dstr = d.sequence.map((e) => e.data).join('');

    expect(astr, bstr);
    expect(bstr, cstr);
    expect(cstr, dstr);

    final aval = a.value.map((e) => e.data).join('');
    final bval = b.value.map((e) => e.data).join('');
    final cval = c.value.map((e) => e.data).join('');
    final dval = d.value.map((e) => e.data).join('');

    expect(aval, bval);
    expect(bval, cval);
    expect(cval, dval);
  });
}

void mergeFail() {
  CausalTree<String> a;
  CausalTree<String> b;

  test('Merge CTRLDEL Merge', () {
    a = CausalTree<String>(1, onLocalUpdate: (entry) {
      b.mergeRemoteEntries([entry]);
    });
    b = CausalTree<String>(2, onLocalUpdate: (entry) {
      a.mergeRemoteEntries([entry]);
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

    b.mergeRemoteEntries(all);
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

    a.mergeRemoteEntries([b.insert(all[2], 'L')]);

    b.mergeRemoteEntries(a.sequence);
    print(a.toString());
    print(b.toString());
  });
}
