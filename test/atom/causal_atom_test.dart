import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'package:test/test.dart';

void main() {
  group('simple CausalAtom without cause', () {
    test('LC', () {
      final clock = LogicalTime(0, 0xff);
      final a = CausalAtom<String>(clock, null, 'hans');

      expect(a.data, 'hans');
      expect(a.clockString, 'Sff@T0');
      expect(a.causeString, null);
    });

    test('HLC', () {
      final clock = Hlc(0, 1, 0xff);
      final a = CausalAtom<String>(clock, null, 'hans');

      expect(a.data, 'hans');
      expect(a.clockString, 'Sff@T0-1');
      expect(a.causeString, null);
    });
  });

  group('simple CausalAtom with cause', () {
    test('LC', () {
      final a1 = CausalAtom<String>(LogicalTime(0, 0xff), null, 'hans');
      final a2 = CausalAtom<String>(LogicalTime(1, 0xff), a1.clock, 'hans');

      expect(a1.data, 'hans');
      expect(a1.clockString, 'Sff@T0');
      expect(a1.causeString, null);

      expect(a2.data, 'hans');
      expect(a2.clockString, 'Sff@T1');
      expect(a2.causeString, 'Sff@T0');
    });

    test('HLC', () {
      final a1 = CausalAtom<String>(Hlc(0, 0, 0xff), null, 'hans');
      final a2 = CausalAtom<String>(Hlc(1, 0, 0xff), a1.clock, 'hans');

      expect(a1.data, 'hans');
      expect(a1.clockString, 'Sff@T0-0');
      expect(a1.causeString, null);

      expect(a2.data, 'hans');
      expect(a2.clockString, 'Sff@T1-0');
      expect(a2.causeString, 'Sff@T0-0');
    });
  });

  group('CausalAtom comparing', () {
    String comStr(bool b) => b ? 'same'.padRight(10, ' ') : 'different'.padRight(10, ' ');

    for (var t1 in [0, 1]) {
      for (var t2 in [0, 1]) {
        for (var site1 in [111, 222]) {
          for (var site2 in [111, 222]) {
            for (var data1 in ['one', 'two']) {
              for (var data2 in ['one', 'two']) {
                final a1 = CausalAtom<String>(LogicalTime(t1, site1), null, data1);
                final a2 = CausalAtom<String>(LogicalTime(t2, site2), null, data2);

                test(
                    'LC without causal - time: ${comStr(t1 == t2)} - sites : ${comStr(site1 == site2)} - data ${comStr(data1 == data2)}',
                    () {
                  if (t1 == t2 && site1 == site2 && data1 == data2) {
                    expect(a1 == a2, isTrue);
                    expect(a2 == a1, isTrue);

                    expect(a1 != a2, isFalse);
                    expect(a2 != a1, isFalse);
                  } else {
                    expect(a1 == a2, isFalse);
                    expect(a2 == a1, isFalse);

                    expect(a1 != a2, isTrue);
                    expect(a2 != a1, isTrue);
                  }
                });
              }
            }
          }
        }
      }
    }

    // test('LC without causal 3', () {
    //   final a1 = CausalAtom<String>(LogicalTime(0, 255), null, 'hans');
    //   final a2 = CausalAtom<String>(LogicalTime(0, 255), null, 'hans');

    //   final a3 = CausalAtom<String>(LogicalTime(1, 255), a1.clock, 'hans');
    //   final a4 = CausalAtom<String>(LogicalTime(1, 255), a1.clock, 'hans2');

    //   final a5 = CausalAtom<String>(LogicalTime(0, 256), a1.clock, 'hans');
    //   final a6 = CausalAtom<String>(LogicalTime(1, 256), a1.clock, 'hans');

    //   // Equaliy
    //   expect(a1 == a2, isTrue);
    //   expect(a1 != a2, isFalse);

    //   expect(a2 == a2, isTrue);
    //   expect(a2 != a2, isFalse);

    //   expect(a1 == a3, isFalse);
    //   expect(a1 != a3, isTrue);

    //   expect(a1 == a4, isFalse);
    //   expect(a1 != a4, isTrue);

    //   expect(a1 == a5, isFalse);
    //   expect(a1 != a5, isTrue);

    //   // atom 2
    //   expect(a2 == a1, isTrue);
    //   expect(a2 != a1, isFalse);

    //   expect(a2 == a3, isFalse);
    //   expect(a2 != a3, isTrue);

    //   expect(a2 == a4, isFalse);
    //   expect(a2 != a4, isTrue);
    // });

    // test('HLC', () {
    //   final a1 = CausalAtom<String>(Hlc(0, 0, 255), null, 'hans');
    //   final a2 = CausalAtom<String>(Hlc(1, 0, 255), a1.clock, 'hans');
    //   final a3 = CausalAtom<String>(Hlc(1, 0, 256), a1.clock, 'hans2');

    //   expect(CausalAtom.isSibling(a1, a2), isFalse);
    //   expect(CausalAtom.isSibling(a2, a1), isFalse);

    //   expect(CausalAtom.isSibling(a1, a3), isFalse);
    //   expect(CausalAtom.isSibling(a3, a1), isFalse);

    //   expect(CausalAtom.isSibling(a2, a3), isTrue);
    //   expect(CausalAtom.isSibling(a3, a2), isTrue);
    // });
  });

  group('CausalAtom siblings', () {
    test('LC', () {
      final a1 = CausalAtom<String>(LogicalTime(0, 255), null, 'hans');
      final a2 = CausalAtom<String>(LogicalTime(1, 255), a1.clock, 'hans');
      final a3 = CausalAtom<String>(LogicalTime(1, 256), a1.clock, 'hans2');

      expect(CausalAtom.isSibling(a1, a2), isFalse);
      expect(CausalAtom.isSibling(a2, a1), isFalse);
      expect(CausalAtom.isSibling(a1, a3), isFalse);
      expect(CausalAtom.isSibling(a3, a1), isFalse);

      expect(CausalAtom.isSibling(a2, a3), isTrue);
      expect(CausalAtom.isSibling(a3, a2), isTrue);
    });

    test('HLC', () {
      final a1 = CausalAtom<String>(Hlc(0, 0, 255), null, 'hans');
      final a2 = CausalAtom<String>(Hlc(1, 0, 255), a1.clock, 'hans');
      final a3 = CausalAtom<String>(Hlc(1, 0, 256), a1.clock, 'hans2');

      expect(CausalAtom.isSibling(a1, a2), isFalse);
      expect(CausalAtom.isSibling(a2, a1), isFalse);

      expect(CausalAtom.isSibling(a1, a3), isFalse);
      expect(CausalAtom.isSibling(a3, a1), isFalse);

      expect(CausalAtom.isSibling(a2, a3), isTrue);
      expect(CausalAtom.isSibling(a3, a2), isTrue);
    });
  });

  group('CausalAtom leftisleft', () {
    test('LC', () {
      final a1 = CausalAtom<String>(LogicalTime(0, 255), null, 'hans');
      final a2 = CausalAtom<String>(LogicalTime(1, 255), a1.clock, 'hans');
      final a3 = CausalAtom<String>(LogicalTime(1, 256), a1.clock, 'hans2');

      expect(CausalAtom.leftIsLeft(a1, a2), isFalse);
      expect(CausalAtom.leftIsLeft(a2, a1), isTrue);

      expect(CausalAtom.leftIsLeft(a1, a3), isFalse);
      expect(CausalAtom.leftIsLeft(a3, a1), isFalse);

      expect(CausalAtom.leftIsLeft(a2, a3), isTrue);
      expect(CausalAtom.leftIsLeft(a3, a2), isTrue);
    });

    // test('HLC', () {
    //   final a1 = CausalAtom<String>(Hlc(0, 0, 0xff), null, 'hans');
    //   final a2 = CausalAtom<String>(Hlc(1, 0, 0xff), a1.clock, 'hans');
    //   final a3 = CausalAtom<String>(Hlc(1, 0, 0xff1), a1.clock, 'hans2');

    //   expect(CausalAtom.isSibling(a1, a2), isFalse);
    //   expect(CausalAtom.isSibling(a2, a1), isFalse);
    //   expect(CausalAtom.isSibling(a1, a3), isFalse);
    //   expect(CausalAtom.isSibling(a3, a1), isFalse);

    //   expect(CausalAtom.isSibling(a2, a3), isTrue);
    //   expect(CausalAtom.isSibling(a3, a2), isTrue);
    // });
  });
}
