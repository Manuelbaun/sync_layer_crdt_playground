import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';
import 'package:sync_layer/crdts/causal_tree/causal_tree.dart';
import 'package:sync_layer/crdts/causal_tree/lc2.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

void main() {
  CausalTree<String> a;
  CausalTree<String> b;
  CausalTree<String> c;
  CausalTree<String> d;

  setUp(() {
    a = CausalTree<String>(1);
    b = CausalTree<String>(2);
    c = CausalTree<String>(3);
    d = CausalTree<String>(4);

    // final stop = Stopwatch();
    // stop.start();

    final unsubscribeA = a.stream.listen((atom) {
      b.mergeRemoteAtoms([atom]);
      c.mergeRemoteAtoms([atom]);
      d.mergeRemoteAtoms([atom]);
    });

    final unsubscribeB = b.stream.listen((atom) {
      a.mergeRemoteAtoms([atom]);
      c.mergeRemoteAtoms([atom]);
      d.mergeRemoteAtoms([atom]);
    });

    final unsubscribeC = c.stream.listen((atom) {
      a.mergeRemoteAtoms([atom]);
      b.mergeRemoteAtoms([atom]);
      d.mergeRemoteAtoms([atom]);
    });

    final unsubscribeD = d.stream.listen((atom) {
      a.mergeRemoteAtoms([atom]);
      b.mergeRemoteAtoms([atom]);
      c.mergeRemoteAtoms([atom]);
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
      final d10 = d.insert(aA, 'S');
      final d11 = d.insert(d10, 'P');
      final d12 = d.insert(d11, 'A');
      final d13 = d.insert(d12, 'C');
      final d14 = d.insert(d13, 'E');
    });
  });

  test('subscription Merge', () {
    measureExecution('Tree print time: ', () {
      final str = a.toString();
    });

    print('$a - ${a.length}: ${a.deleteAtomsLength}');
    print('$b - ${b.length}: ${b.deleteAtomsLength}');
    print('$c - ${c.length}: ${c.deleteAtomsLength}');
    print('$d - ${d.length}: ${d.deleteAtomsLength}');

    var index = 0;
    final abEqual = a.sequence.every((a) => a == b.sequence[index++]);

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
          siteid: {4},
          semantic: FilterSemantic.AND,
        );
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'SPACE');
    });
    test('filter by one siteid', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by one siteid', () {
        filteredAtoms = a.filtering(siteid: {2});
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'DELACT');
    });

    test('filter by two siteids', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by two siteids', () {
        filteredAtoms = a.filtering(siteid: {4, 2});
      });

      final res = filteredAtoms.map((a) => a.data).join('');
      expect(res, 'SPACEDELACT');
    });

    test('filter by one siteids and timestamp', () {
      List<CausalEntry> filteredAtoms;
      measureExecution('filter by one siteids and timestamp', () {
        filteredAtoms = a.filtering(
          siteid: {2},
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
