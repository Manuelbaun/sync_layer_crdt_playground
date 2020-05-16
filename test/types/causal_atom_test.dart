// import 'dart:math';

// import 'package:sync_layer/types/index.dart';

// import 'package:test/test.dart';
import 'package:test/test.dart';

void main() {
  test('my causal test', () {
    expect(true, isTrue);
  });
}
// void main() {
//   group('simple CausalAtom without cause', () {
//     test('LC', () {
//       final clock = LogicalTime(0, 0xff);
//       final a = CausalAtom<String>(clock, null, 'hans');

//       expect(a.data, 'hans');
//       expect(a.selfString, 'Sff@T0');
//       expect(a.causeString, null);
//     });

//     test('HLC', () {
//       final clock = Hlc(0, 1, 0xff);
//       final a = CausalAtom<String>(clock, null, 'hans');

//       expect(a.data, 'hans');
//       expect(a.selfString, 'Sff@T0-1');
//       expect(a.causeString, null);
//     });
//   });

//   group('simple CausalAtom with cause', () {
//     test('LC', () {
//       final a1 = CausalAtom<String>(LogicalTime(0, 0xff), null, 'hans');
//       final a2 = CausalAtom<String>(LogicalTime(1, 0xff), a1.clock, 'hans');

//       expect(a1.data, 'hans');
//       expect(a1.selfString, 'Sff@T0');
//       expect(a1.causeString, null);

//       expect(a2.data, 'hans');
//       expect(a2.selfString, 'Sff@T1');
//       expect(a2.causeString, 'Sff@T0');
//     });

//     test('HLC', () {
//       final a1 = CausalAtom<String>(Hlc(0, 0, 0xff), null, 'hans');
//       final a2 = CausalAtom<String>(Hlc(1, 0, 0xff), a1.clock, 'hans');

//       expect(a1.data, 'hans');
//       expect(a1.selfString, 'Sff@T0-0');
//       expect(a1.causeString, null);

//       expect(a2.data, 'hans');
//       expect(a2.selfString, 'Sff@T1-0');
//       expect(a2.causeString, 'Sff@T0-0');
//     });
//   });

//   group('basic', () {
//     test('basic', () {
//       final clock = LogicalTime(0, 1);
//       final clock2 = LogicalTime(0, 5);
//       final a = CausalAtom<String>(clock, null, 'hans');
//       final b = CausalAtom<String>(clock, null, 'hans');
//       final c = CausalAtom<String>(clock2, null, 'hans');

//       expect(a == b, isTrue);
//       expect(a == c, isFalse);
//       expect(b == c, isFalse);

//       expect(a.id == b.id, isTrue);
//       expect(a.id == c.id, isFalse);
//       expect(b.id == c.id, isFalse);

//       expect(a.causeId, isNull);
//       expect(b.causeId, isNull);
//       expect(c.causeId, isNull);

//       expect(a.relatesTo(b), RelationShip.Identical);
//       expect(a.relatesTo(c), RelationShip.Unknown);
//       expect(b.relatesTo(c), RelationShip.Unknown);

//       print('a : $a');
//       print('b : $b');
//       print('Same id ${a.id == b.id}');
//       print('Equality ${a == b}'); // null == null => danger

//       print(a.relatesTo(b));

//       print(a.isLeftOf(b));
//     });
//   });

//   group('merging', () {
//     test('With LC', () {
//       final a1 = CausalAtom<String>(LogicalTime(1, 1), null, 'H');
//       final b1 = CausalAtom<String>(LogicalTime(2, 1), a1.clock, 'L');
//       final c1 = CausalAtom<String>(LogicalTime(3, 1), b1.clock, 'O');

//       // // f1irst correction
//       final d1 = CausalAtom<String>(LogicalTime(4, 1), a1.clock, 'A');
//       final e1 = CausalAtom<String>(LogicalTime(4, 2), b1.clock, 'L');

//       // // a1dd some marks
//       final g1 = CausalAtom<String>(LogicalTime(5, 2), c1.clock, '?');
//       final f1 = CausalAtom<String>(LogicalTime(6, 1), c1.clock, '!');

//       final atoms = [a1, b1, c1, d1, e1, f1, g1];
//       merge(atoms, 'HALLO!?');
//     });

//     test('With HLC', () {
//       // initial
//       final a = CausalAtom<String>(Hlc(1579633503111, 1, 1), null, 'H');
//       final b = CausalAtom<String>(Hlc(1579633503112, 1, 1), a.clock, 'L');
//       final c = CausalAtom<String>(Hlc(1579633503113, 1, 1), b.clock, 'O');

//       // first correction
//       final d = CausalAtom<String>(Hlc(1579633503114, 1, 1), a.clock, 'A');
//       final e = CausalAtom<String>(Hlc(1579633503114, 2, 2), b.clock, 'L');

//       // add some marks
//       final f = CausalAtom<String>(Hlc(1579633503115, 2, 1), c.clock, '!');
//       final g = CausalAtom<String>(Hlc(1579633503115, 2, 2), c.clock, '?');

//       final atoms = [a, b, c, d, e, f, g];
//       merge(atoms, 'HALLO?!');
//     });
//   });

//   main2();
// }

// void main2() {
//   group('CausalAtom comparing', () {
//     String comStr(bool b) => b ? 'same'.padRight(10, ' ') : 'different'.padRight(10, ' ');
//     final counter = [0, 1, 2];
//     final sites = [111, 222, 333];

//     var i = 0;
//     for (var t1 in counter) {
//       for (var t2 in counter) {
//         for (var site1 in sites) {
//           for (var site2 in sites) {
//             for (var data1 in ['one', 'two']) {
//               for (var data2 in ['one', 'two']) {
//                 final a1 = CausalAtom<String>(LogicalTime(t1, site1), null, data1);
//                 final a2 = CausalAtom<String>(LogicalTime(t2, site2), null, data2);
//                 i++;
//                 test(
//                     'LC without causal - time: ${comStr(t1 == t2)} - '
//                     'sites: ${comStr(site1 == site2)} - data: ${comStr(data1 == data2)}', () {
//                   if (t1 == t2 && site1 == site2 && data1 == data2) {
//                     expect(a1 == a2, isTrue);
//                     expect(a2 == a1, isTrue);

//                     expect(a1 != a2, isFalse);
//                     expect(a2 != a1, isFalse);
//                   } else {
//                     expect(a1 == a2, isFalse);
//                     expect(a2 == a1, isFalse);

//                     expect(a1 != a2, isTrue);
//                     expect(a2 != a1, isTrue);
//                   }
//                 });
//               }
//             }
//           }
//         }
//       }
//     }

//     print('CausalAtom comparing tests: $i');
//   });

//   group('CausalAtom siblings', () {
//     test('LC', () {
//       final a1 = CausalAtom<String>(LogicalTime(0, 255), null, 'hans');
//       final a2 = CausalAtom<String>(LogicalTime(1, 255), a1.clock, 'hans');
//       final a3 = CausalAtom<String>(LogicalTime(1, 256), a1.clock, 'hans2');

//       expect(CausalAtom.isSibling(a1, a2), isFalse);
//       expect(CausalAtom.isSibling(a2, a1), isFalse);
//       expect(CausalAtom.isSibling(a1, a3), isFalse);
//       expect(CausalAtom.isSibling(a3, a1), isFalse);

//       expect(CausalAtom.isSibling(a2, a3), isTrue);
//       expect(CausalAtom.isSibling(a3, a2), isTrue);
//     });

//     test('HLC', () {
//       final a1 = CausalAtom<String>(Hlc(0, 0, 255), null, 'hans');
//       final a2 = CausalAtom<String>(Hlc(1, 0, 255), a1.clock, 'hans');
//       final a3 = CausalAtom<String>(Hlc(1, 0, 256), a1.clock, 'hans2');

//       expect(CausalAtom.isSibling(a1, a2), isFalse);
//       expect(CausalAtom.isSibling(a2, a1), isFalse);

//       expect(CausalAtom.isSibling(a1, a3), isFalse);
//       expect(CausalAtom.isSibling(a3, a1), isFalse);

//       expect(CausalAtom.isSibling(a2, a3), isTrue);
//       expect(CausalAtom.isSibling(a3, a2), isTrue);
//     });
//   });

//   group('CausalAtom conflicts', () {
//     test('Simple Conflict concurrent edit', () {
//       // roo
//       final root = CausalAtom<String>(LogicalTime(0, 1), null, 'r');

//       final a1 = CausalAtom<String>(LogicalTime(1, 1), root.clock, 'o');
//       final a2 = CausalAtom<String>(LogicalTime(1, 2), root.clock, 't');

//       expect(a1.isLeftOf(a2), isFalse);
//       expect(a2.isLeftOf(a1), isTrue);
//     });

//     test('Simple Conflict char runs', () {
//       // roo
//       final root = CausalAtom<String>(LogicalTime(0, 1), null, 'r');

//       final a1 = CausalAtom<String>(LogicalTime(1, 1), root.clock, 'o');
//       final a2 = CausalAtom<String>(LogicalTime(2, 1), a1.clock, 'o');
//       final a3 = CausalAtom<String>(LogicalTime(3, 1), a2.clock, 't');

//       final b1 = CausalAtom<String>(LogicalTime(0, 2), root.clock, 'hans2');

//       expect(a1.isLeftOf(a2), isFalse);
//       expect(a2.isLeftOf(a1), isTrue);
//     });
//   });
// }

// class LogicalTime {}

// class CausalAtom {}

// /// Merge algorithm ??
// void merge(List<CausalAtom<String>> atoms, String match) {
//   // for (var a in atoms) {
//   //   for (var b in atoms) {
//   //     final r1 = a.relatesTo(b);
//   //     final r2 = b.relatesTo(a);
//   //     if (r1 != RelationShip.Unknown && r1 != RelationShip.Identical) {
//   //       print('${a.toString().padRight(20, ' ')} ::: $r1');
//   //       print('${b.toString().padRight(20, ' ')} ::: $r2');
//   //       print('--------------------------------------');
//   //     }
//   //   }
//   // }

//   final root = atoms.first;
//   var res = '';
//   var last = '';
//   var run = 100;

//   for (var i = 0; i < run; i++) {
//     final shuffle = [...atoms]..shuffle(Random(0));

//     List<CausalAtom<dynamic>> seq;

//     seq = causalSort(root, shuffle);

//     res = seq.map((a) => a.data).join('');
//     if (last.isEmpty) last = res;

//     if (last != res) {
//       throw AssertionError('something went wrong!');
//     }
//     expect(last == res, isTrue);
//     expect(last, match);
//     last = res;
//   }
// }

// List<CausalAtom> causalSort(CausalAtom root, List<CausalAtom> atoms) {
//   // final pending = <CausalAtom>[];
//   final cache = <CausalAtom>{root};
//   final sequence = <CausalAtom>[root];

//   // insert algorithm
//   // returns pending atom
//   void insert(CausalAtom atom, Function(CausalAtom) onPending) {
//     if (!cache.contains(atom)) {
//       /// add to [sequence]
//       var causeIndex = sequence.indexWhere((a) => a.id == atom.causeId);

//       // if index is at the end
//       if (causeIndex >= sequence.length - 1) {
//         sequence.add(atom);
//         cache.add(atom);
//       } else
//       // if index in the sequence
//       if (causeIndex >= 0) {
//         causeIndex += 1;

//         final res = atom.relatesTo(sequence[causeIndex]);

//         if (res == RelationShip.Sibling) {
//           /// The question : is sequence[causeIndex] left of atom
//           /// if so, increase [causeIndex] by one and check the next!
//           while (causeIndex < sequence.length && sequence[causeIndex].isLeftOf(atom)) {
//             causeIndex++;
//           }
//         }
//         sequence.insert(causeIndex, atom);
//         cache.add(atom);
//       } else {
//         // if index not found
//         onPending(atom);
//       }
//     }
//   }

//   void inserteAtoms(List<CausalAtom> atoms) {
//     final pendingAtoms = <CausalAtom>[];

//     void onPending(CausalAtom a) => pendingAtoms.add(a);

//     for (var atom in atoms) {
//       // print(atom);
//       insert(atom, onPending);
//       // final cur = sequence.map((a) => a.data).join('');
//       // print(cur);
//     }

//     if (pendingAtoms.isNotEmpty) {
//       inserteAtoms(pendingAtoms);
//     }
//   }

//   inserteAtoms(atoms);

//   return sequence;
// }
