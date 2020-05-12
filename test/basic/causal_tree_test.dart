// import 'package:sync_layer/impl/syncable_causal_tree_imple.dart';
// import 'package:test/test.dart';

// void main() {
//   CausalTree<String> a;
//   CausalTree<String> b;
//   CausalTree<String> c;
//   CausalTree<String> d;

//   setUp(() {
//     a = CausalTree<String>(SiteId(1));
//     b = CausalTree<String>(SiteId(2));
//     c = CausalTree<String>(SiteId(3));
//     d = CausalTree<String>(SiteId(4));

//     final stop = Stopwatch();
//     stop.start();

//     final unsubscribeA = a.subscribe((atom) {
//       d.mergeRemoteAtoms([atom]);
//       c.mergeRemoteAtoms([atom]);
//       b.mergeRemoteAtoms([atom]);
//     });

//     final unsubscribeB = b.subscribe((atom) {
//       c.mergeRemoteAtoms([atom]);
//       a.mergeRemoteAtoms([atom]);
//       d.mergeRemoteAtoms([atom]);
//     });

//     final unsubscribeC = c.subscribe((atom) {
//       b.mergeRemoteAtoms([atom]);
//       d.mergeRemoteAtoms([atom]);
//       a.mergeRemoteAtoms([atom]);
//     });

//     final unsubscribeD = d.subscribe((atom) {
//       b.mergeRemoteAtoms([atom]);
//       a.mergeRemoteAtoms([atom]);
//       c.mergeRemoteAtoms([atom]);
//     });

//     final a1 = a.insert(null, 'C');
//     final a2 = a.insert(a1, 'M');
//     final a3 = a.insert(a2, 'D');

//     a.timestamp = 5;
//     final a6 = a.delete(a2);
//     final a7 = a.delete(a3);
//     final a8 = a.insert(a1, 'T');
//     final a9 = a.insert(a8, 'R');
//     final aA = a.insert(a9, 'L');

//     // ------------- B
//     b.timestamp = 5;
//     final b6 = b.insert(a3, 'D');
//     final b7 = b.insert(b6, 'E');
//     final b8 = b.insert(b7, 'L');

//     final b9 = b.insert(b8, 'A');
//     final bA = b.insert(b9, 'C');
//     final bB = b.insert(bA, 'T');

//     c.timestamp = 6;
//     final c7 = c.insert(a3, 'A');
//     final c8 = c.insert(c7, 'L');
//     final c9 = c.insert(c8, 'T');

//     // ------------- C
//     d.timestamp = 10;
//     final d10 = d.insert(aA, 'S');
//     final d11 = d.insert(d10, 'P');
//     final d12 = d.insert(d11, 'A');
//     final d13 = d.insert(d12, 'C');
//     final d14 = d.insert(d13, 'E');

//     stop.stop();

//     unsubscribeA();
//     unsubscribeB();
//     unsubscribeC();
//     unsubscribeD();
//     print('Elapsed time overall: ${stop.elapsedMicroseconds}');
//   });

//   test('subscription Merge', () {
//     final s = Stopwatch();
//     s.start();
//     final str = a.toString();
//     s.stop();
//     print('Elapsed time print : ${s.elapsedMicroseconds}');

//     print('$a - ${a.length}: ${a.allAtomsLength}');
//     print('$b - ${b.length}: ${b.allAtomsLength}');
//     print('$c - ${c.length}: ${c.allAtomsLength}');
//     print('$d - ${d.length}: ${d.allAtomsLength}');

//     var index = 0;
//     final abEqual = a.atoms.every((a) => a == b.atoms[index++]);

//     index = 0;
//     final acEqual = a.atoms.every((a) => a == c.atoms[index++]);

//     index = 0;
//     final adEqual = a.atoms.every((a) => a == d.atoms[index++]);

//     expect(abEqual, true);
//     expect(acEqual, true);
//     expect(adEqual, true);

//     expect(a.toString(), 'CTRLSPACEALTDELACT');
//     expect(b.toString(), 'CTRLSPACEALTDELACT');
//     expect(c.toString(), 'CTRLSPACEALTDELACT');
//     expect(d.toString(), 'CTRLSPACEALTDELACT');
//   });

//   group('filter 1 tree', () {
//     test('filter by timestamp', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter(a, timestamp: 8);
//       });
//       print('filter by timestamp: Filter Time: $time us');

//       final str = filterdTree.toString();
//       // a.atoms.forEach(print);
//       expect(str, 'CTALDEL');
//     });

//     test('filter by one siteid', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter(a, siteid: {2});
//       });
//       print('filter by one siteid: Filter Time: $time us');
//       expect(filterdTree.toString(), 'DELACT');
//     });

//     test('filter by two siteids', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter(a, siteid: {4, 2});
//       });
//       print('filter by two siteids: Filter Time: $time us');
//       expect(filterdTree.toString(), 'SPACEDELACT');
//     });

//     test('filter by one siteids and timestamp', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter(a, siteid: {2}, timestamp: 8);
//       });
//       print('filter by one siteids and timestamp: Filter Time: $time us');
//       // a.atoms.forEach(print);
//       expect(filterdTree.toString(), 'DEL');
//     });
//   });

//   group('filter 2 tree', () {
//     test('filter by timestamp', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter2(a, timestamp: 8);
//       });
//       print('filter by timestamp: Filter Time: $time us');

//       final str = filterdTree.toString();
//       // a.atoms.forEach(print);
//       expect(str, 'CTALDEL');
//     });

//     test('filter by one siteid', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter2(a, siteid: {2});
//       });
//       print('filter by one siteid: Filter Time: $time us');
//       expect(filterdTree.toString(), 'DELACT');
//     });

//     test('filter by two siteids', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter2(a, siteid: {2, 4});
//       });
//       print('filter by two siteids: Filter Time: $time us');
//       filterdTree.atoms.forEach(print);
//       expect(filterdTree.toString(), 'SPACEDELACT');
//       // Skip('needs double check');
//     });

//     test('filter by one siteids and timestamp', () {
//       var filterdTree;
//       var time = measureTime('filter by siteid', () {
//         filterdTree = CausalTree.filter2(a, siteid: {2}, timestamp: 8);
//       });
//       print('filter by one siteids and timestamp: Filter Time: $time us');

//       expect(filterdTree.toString(), 'DEL');
//     });
//   });
// }
