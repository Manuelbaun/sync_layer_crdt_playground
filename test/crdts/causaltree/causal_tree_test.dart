import 'package:sync_layer/crdts/causal_tree/index.dart';
import 'package:sync_layer/types/logical_clock.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

void main() {
  CausalTree<String> a;
  CausalTree<String> b;
  CausalTree<String> c;
  CausalTree<String> d;

  setUp(() {
    a = CausalTree<String>(
      1,
      //  onChange: (atom) {
      //   b.mergeRemoteEntriees([atom]);
      //   c.mergeRemoteEntriees([atom]);
      //   d.mergeRemoteEntriees([atom]);
      // }
    );

    b = CausalTree<String>(
      2,
      // onChange:
      //  (atom) {
      //   a.mergeRemoteEntriees([atom]);
      //   c.mergeRemoteEntriees([atom]);
      //   d.mergeRemoteEntriees([atom]);
      // }
    );

    c = CausalTree<String>(
      3,
      // onChange: (atom) {
      //   a.mergeRemoteEntriees([atom]);
      //   b.mergeRemoteEntriees([atom]);
      //   d.mergeRemoteEntriees([atom]);
      // }
    );

    d = CausalTree<String>(
      4,
      // onChange: (atom) {
      //   a.mergeRemoteEntriees([atom]);
      //   b.mergeRemoteEntriees([atom]);
      //   c.mergeRemoteEntriees([atom]);
      // }
    );

    measureExecution('add and merge', () {
      final a1 = a.insert(null, 'C');
      final a2 = a.insert(a1, 'M');
      final a3 = a.insert(a2, 'D');

      b.mergeRemoteEntriees(a.sequence);
      c.mergeRemoteEntriees(a.sequence);
      d.mergeRemoteEntriees(a.sequence);

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
      d.mergeRemoteEntriees(a.sequence);
      final d10 = d.insert(aA, 'S');
      final d11 = d.insert(d10, 'P');
      final d12 = d.insert(d11, 'A');
      final d13 = d.insert(d12, 'C');
      final d14 = d.insert(d13, 'E');

      /// all changed merge into a
      a.mergeRemoteEntriees(b.sequence);
      a.mergeRemoteEntriees(c.sequence);
      a.mergeRemoteEntriees(d.sequence);

      /// merge new state of a into b, c, d
      b.mergeRemoteEntriees(a.sequence);
      c.mergeRemoteEntriees(a.sequence);
      d.mergeRemoteEntriees(a.sequence);
    });
  });

  test('subscription Merge', () {
    measureExecution('Tree print time: ', () {
      final str = a.toString();
    });

    print('$a - ${a.length}: ${a.deletedLength}');
    print('$b - ${b.length}: ${b.deletedLength}');
    print('$c - ${c.length}: ${c.deletedLength}');
    print('$d - ${d.length}: ${d.deletedLength}');

    final sa = a.sequence.map((e) => e.data).join(' ');
    final sb = b.sequence.map((e) => e.data).join(' ');
    final sc = c.sequence.map((e) => e.data).join(' ');
    final sd = d.sequence.map((e) => e.data).join(' ');

    print(sa);
    print(sb);
    print(sc);
    print(sd);

    var index = 0;
    final abEqual = a.sequence.every((a) {
      final e = a == b.sequence[index++];
      print('$a == ${b.sequence[index - 1]} : $e');
      return e;
    });

    index = 0;
    final acEqual = a.sequence.every((a) => a == c.sequence[index++]);

    index = 0;
    final adEqual = a.sequence.every((a) => a == d.sequence[index++]);

    expect(a.toString(), 'CTRLSPACEALTDELACT');
    expect(b.toString(), 'CTRLSPACEALTDELACT');
    expect(c.toString(), 'CTRLSPACEALTDELACT');
    expect(d.toString(), 'CTRLSPACEALTDELACT');

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

// S01@T01->S-1@T00:   C == S01@T01->S-1@T00:   C : true
// S01@T08->S01@T01:   T == S01@T08->S01@T01:   T : true
// S01@T09->S01@T08:   R == S01@T09->S01@T08:   R : true
// S01@T10->S01@T09:   L == S01@T10->S01@T09:   L : true
// S04@T11->S01@T10:   S == S04@T11->S01@T10:   S : true
// S04@T12->S04@T11:   P == S04@T12->S04@T11:   P : true
// S04@T13->S04@T12:   A == S04@T13->S04@T12:   A : true
// S04@T14->S04@T13:   C == S04@T14->S04@T13:   C : true
// S04@T15->S04@T14:   E == S04@T15->S04@T14:   E : true
// S01@T02->S01@T01:   M == S01@T02->S01@T01:   M : true
// S01@T06->S01@T02:null == S01@T06->S01@T02:null : true
// S01@T03->S01@T02:   D == S01@T03->S01@T02:   D : true
// S03@T07->S01@T03:   A == S03@T07->S01@T03:   A : true
// S03@T08->S03@T07:   L == S03@T08->S03@T07:   L : true
// S03@T09->S03@T08:   T == S03@T09->S03@T08:   T : true
// S01@T07->S01@T03:null == S02@T06->S01@T03:   D : false
// S02@T06->S01@T03:   D == S01@T07->S01@T03:null : false
// S02@T07->S02@T06:   E == S02@T07->S02@T06:   E : true
// S02@T08->S02@T07:   L == S02@T08->S02@T07:   L : true
// S02@T09->S02@T08:   A == S02@T09->S02@T08:   A : true
// S02@T10->S02@T09:   C == S02@T10->S02@T09:   C : true
// S02@T11->S02@T10:   T == S02@T11->S02@T10:   T : true
