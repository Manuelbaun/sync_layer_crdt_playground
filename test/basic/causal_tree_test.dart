import 'package:sync_layer/impl/syncable_causal_tree_imple.dart';
import 'package:sync_layer/timestamp/index.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

// void main() {
//   final tree = CausalTree(111);
//   final root = tree.push('root');

//   final tree2 = CausalTree(222);
//   tree2.mergeRemoteAtoms([root]);

//   final h1 = tree.push(1);
//   final h2 = tree.push(2);
//   final h3 = tree.push(3);

//   final b = h1.toBytes();
//   print(b);
//   final a = CausalAtom.fromBytes(b);
//   print(a);

//   tree.insert(h1, 4);
//   tree.insert(h2, 5);

//   tree.atoms.forEach(print);
//   print('-----------');

//   final p1 = tree2.push('B');
//   final p2 = tree2.push('B');
//   final p3 = tree2.push('C');

//   tree2.atoms.forEach(print);

//   // merge 1

//   print('-----------');
//   tree2.mergeRemoteAtoms(tree.atoms);
//   tree2.atoms.forEach(print);

//   print('-----------');

//   tree.mergeRemoteAtoms(tree2.atoms);
//   tree.atoms.forEach(print);

//   print('----------------');

//   final bytes = tree.atoms.map((a) => a.toBytes());
//   bytes.forEach((b) => print(b.length));
//   // print(bytes);
//   final allAtoms = bytes.map((b) => CausalAtom.fromBytes(b));

//   allAtoms.forEach((a) => print(a));
// }

void main() {
  CausalTree<String> a;
  CausalTree<String> b;
  CausalTree<String> c;
  CausalTree<String> d;

  setUp(() {
    a = CausalTree<String>(1);
    b = CausalTree<String>(2);
    c = CausalTree<String>(3);
    d = CausalTree<String>(3);

    final stop = Stopwatch();
    stop.start();

    final unsubscribeA = a.stream.listen((atom) {
      d.mergeRemoteAtoms([atom]);
      c.mergeRemoteAtoms([atom]);
      b.mergeRemoteAtoms([atom]);
    });

    final unsubscribeB = b.stream.listen((atom) {
      c.mergeRemoteAtoms([atom]);
      a.mergeRemoteAtoms([atom]);
      d.mergeRemoteAtoms([atom]);
    });

    final unsubscribeC = c.stream.listen((atom) {
      b.mergeRemoteAtoms([atom]);
      d.mergeRemoteAtoms([atom]);
      a.mergeRemoteAtoms([atom]);
    });

    final unsubscribeD = d.stream.listen((atom) {
      b.mergeRemoteAtoms([atom]);
      a.mergeRemoteAtoms([atom]);
      c.mergeRemoteAtoms([atom]);
    });

    final a1 = a.insert(null, 'C');
    final a2 = a.insert(a1, 'M');
    final a3 = a.insert(a2, 'D');

    a.localClock = Hlc(0, 5, a.owner);
    final a6 = a.delete(a2);
    final a7 = a.delete(a3);
    final a8 = a.insert(a1, 'T');
    final a9 = a.insert(a8, 'R');
    final aA = a.insert(a9, 'L');

    // ------------- B
    b.localClock = Hlc(0, 5, b.owner);
    final b6 = b.insert(a3, 'D');
    final b7 = b.insert(b6, 'E');
    final b8 = b.insert(b7, 'L');

    final b9 = b.insert(b8, 'A');
    final bA = b.insert(b9, 'C');
    final bB = b.insert(bA, 'T');

    c.localClock = Hlc(0, 5, c.owner);
    final c7 = c.insert(a3, 'A');
    final c8 = c.insert(c7, 'L');
    final c9 = c.insert(c8, 'T');

    // ------------- C
    d.localClock = Hlc(0, 10, d.owner);
    ;
    final d10 = d.insert(aA, 'S');
    final d11 = d.insert(d10, 'P');
    final d12 = d.insert(d11, 'A');
    final d13 = d.insert(d12, 'C');
    final d14 = d.insert(d13, 'E');

    stop.stop();

    print('Elapsed time overall: ${stop.elapsedMicroseconds}');
  });

  test('subscription Merge', () {
    final s = Stopwatch();
    s.start();
    final str = a.toString();
    s.stop();
    print('Elapsed time print : ${s.elapsedMicroseconds}');

    print('$a - ${a.length}: ${a.allAtomsLength}');
    print('$b - ${b.length}: ${b.allAtomsLength}');
    print('$c - ${c.length}: ${c.allAtomsLength}');
    print('$d - ${d.length}: ${d.allAtomsLength}');

    var index = 0;
    final abEqual = a.atoms.every((a) => a == b.atoms[index++]);

    index = 0;
    final acEqual = a.atoms.every((a) => a == c.atoms[index++]);

    index = 0;
    final adEqual = a.atoms.every((a) => a == d.atoms[index++]);

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
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter(a, timestamp: 8);
      });
      print('filter by timestamp: Filter Time: $time us');

      final str = filterdTree.toString();
      // a.atoms.forEach(print);
      expect(str, 'CTALDEL');
    });

    test('filter by one siteid', () {
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter(a, siteid: {2});
      });
      print('filter by one siteid: Filter Time: $time us');
      expect(filterdTree.toString(), 'DELACT');
    });

    test('filter by two siteids', () {
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter(a, siteid: {4, 2});
      });
      print('filter by two siteids: Filter Time: $time us');
      expect(filterdTree.toString(), 'SPACEDELACT');
    });

    test('filter by one siteids and timestamp', () {
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter(a, siteid: {2}, timestamp: 8);
      });
      print('filter by one siteids and timestamp: Filter Time: $time us');
      // a.atoms.forEach(print);
      expect(filterdTree.toString(), 'DEL');
    });
  });

  group('filter 2 tree', () {
    test('filter by timestamp', () {
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter2(a, timestamp: 8);
      });
      print('filter by timestamp: Filter Time: $time us');

      final str = filterdTree.toString();
      // a.atoms.forEach(print);
      expect(str, 'CTALDEL');
    });

    test('filter by one siteid', () {
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter2(a, siteid: {2});
      });
      print('filter by one siteid: Filter Time: $time us');
      expect(filterdTree.toString(), 'DELACT');
    });

    test('filter by two siteids', () {
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter2(a, siteid: {2, 4});
      });
      print('filter by two siteids: Filter Time: $time us');
      filterdTree.atoms.forEach(print);
      expect(filterdTree.toString(), 'SPACEDELACT');
      // Skip('needs double check');
    });

    test('filter by one siteids and timestamp', () {
      var filterdTree;
      var time = measureExecution('filter by siteid', () {
        filterdTree = CausalTree.filter2(a, siteid: {2}, timestamp: 8);
      });
      print('filter by one siteids and timestamp: Filter Time: $time us');

      expect(filterdTree.toString(), 'DEL');
    });
  });
}
