import 'package:sync_layer/logical_clocks/index.dart';
import 'package:test/test.dart';

var testHlc = Hlc(1579633503119, 42, 1234);

void main() {
  group('Compare < = >', () {
    // 3^6 iteration => 729
    String comStr(bool b) => b ? 'equal'.padRight(10, ' ') : 'different'.padRight(10, ' ');

    final mss = [1579633503119, 1579633503119 + 100, 1579633503119 + 200];

    final counter = [0, 1, 2];
    final sites = [111, 222, 333];
    var i = 1;
    for (var m1 in mss) {
      for (var m2 in mss) {
        for (var c1 in counter) {
          for (var c2 in counter) {
            for (var s1 in sites) {
              for (var s2 in sites) {
                // run tests
                final h1 = Hlc(m1, c1, s1);
                final h2 = Hlc(m2, c2, s2);
                i++;
                compareHLC_Less_Equal_Greater_Tests(comStr, m1, m2, c1, c2, s1, s2, h1, h2);
              }
            }
          }
        }
      }
    }

    print('Compare < = > Tests $i');
  });
  group('Compare Subtract diffs', () {
    final mss = [1579633503119, 1579633503120, 1579633503121];
    final counter = [0, 1, 2];

    var i = 1;
    for (var m1 in mss) {
      for (var m2 in mss) {
        for (var c1 in counter) {
          for (var c2 in counter) {
            // run tests
            final h1 = Hlc(m1, c1, 0);
            final h2 = Hlc(m2, c2, 0);
            i++;
            test('Compare Subtract ms:$m1:$m2:${m1 == m2} counter: $c1:$c2:${c1 == c2}', () {
              final md1 = m1 - m2;
              final md2 = m2 - m1;
              final cd1 = c1 - c2;
              final cd2 = c2 - c1;

              expect((h1 - h2)[0] == md1, isTrue);
              expect((h2 - h1)[0] == md2, isTrue);

              expect((h1 - h2)[1] == cd1, isTrue);
              expect((h2 - h1)[1] == cd2, isTrue);
            });
          }
        }
      }
    }
    print('Compare Subtract diffs Tests $i');
  });

  group('Comparison', () {
    test('Equality', () {
      var hlc = Hlc(1579633503119, 42, 1234);
      expect(testHlc, hlc);
    });

    test('Equality with different nodes', () {
      var hlc = Hlc(1579633503119, 42, 1234);
      expect(testHlc, hlc);
    });

    test('Less than millis', () {
      var hlc = Hlc(1579733503119, 42, 1234);
      expect(testHlc < hlc, isTrue);
    });

    test('Less than counter', () {
      var hlc = Hlc(1579633503119, 43, 1234);
      expect(testHlc < hlc, isTrue);
    });

    test('Fail less than if equals', () {
      var hlc = Hlc(1579633503119, 42, 1234);
      expect(testHlc < hlc, isFalse);
    });

    test('Fail less than if millis and counter disagree', () {
      var hlc = Hlc(1579533503119, 43, 1234);
      expect(testHlc < hlc, isFalse);
    });
  });

  group('String operations', () {
    test('hlc to string', () {
      expect(testHlc.toString(), '16fc97e6b8f-2a-4d2');
    });

    test('Parse hlc', () {
      expect(Hlc.parse('16fc97e6b8f-2a-4d2'), testHlc);
    });
  });

  group('Send', () {
    test('Send before', () {
      var hlc = Hlc.send(testHlc, 1579633503110);

      final r = isNot(testHlc);
      expect(hlc, r);
      expect(hlc.toString(), '16fc97e6b8f-2b-4d2');
    });

    test('Send simultaneous', () {
      var hlc = Hlc.send(testHlc, 1579633503119);
      expect(hlc, isNot(testHlc));
      expect(hlc.toString(), '16fc97e6b8f-2b-4d2');
    });

    test('Send later', () {
      var hlc = Hlc.send(testHlc, 1579733503119);
      expect(hlc, Hlc(1579733503119, 0, 1234));
    });
  });

  group('Receive', () {
    test('Receive before', () {
      var remoteHlc = Hlc(1579633503110, 0, 1234);
      var hlc = Hlc.recv(testHlc, remoteHlc, 1579633503119);
      expect(hlc, isNot(equals(testHlc)));
    });

    test('Receive simultaneous', () {
      var remoteHlc = Hlc(1579633503119, 0, 1234);
      var hlc = Hlc.recv(testHlc, remoteHlc, 1579633503119);
      expect(hlc, isNot(testHlc));
    });

    test('Receive after', () {
      var remoteHlc = Hlc(1579633503119, 0, 1234);
      var hlc = Hlc.recv(testHlc, remoteHlc, 1579633503129);
      expect(hlc, isNot(testHlc));
    });
  });

  group('Clock drifts', () {
    final date1 = DateTime(2020, 3, 0);
    final date2 = DateTime(2020, 4, 0);
    final local = DateTime(2020, 5, 0);

    final hlcD1 = Hlc(date1.millisecondsSinceEpoch, 0, 1234);
    final hlcD2 = Hlc(date2.millisecondsSinceEpoch, 0, 1234);
    final hlcD3 = Hlc(local.millisecondsSinceEpoch, 0, 1234);

    test('Receive Ts in total time order', () {
      // init
      final hlc1 = Hlc.recv(hlcD1, hlcD1);
      // recieve first
      final hlc2 = Hlc.recv(hlc1, hlcD2);
      // recieves second
      final hlc3 = Hlc.recv(hlc2, hlcD3);

      expect(hlc1 < hlc2, isTrue);
      expect(hlc2 < hlc3, isTrue);
    });

    test('Receive ', () {
      // init

      final newLocal1 = Hlc.recv(hlcD1, hlcD1);
      // recieves second
      final newLocal2 = Hlc.recv(newLocal1, hlcD3);
      // recieve first
      final newLocal3 = Hlc.recv(newLocal2, hlcD2);

      expect(newLocal1 < newLocal2, isTrue);
      expect(newLocal1 < newLocal3, isTrue);
      expect(newLocal2 < newLocal3, isTrue);
    });

    test('impossibleTs', () {
      final localD = DateTime.now().millisecondsSinceEpoch;
      final localHlc = Hlc(localD, 0, 1111);

      final remoteD = DateTime.now().millisecondsSinceEpoch;
      final remoteHlc = Hlc(remoteD, 0, 9999);

      expect(localHlc == remoteHlc, isFalse);
      expect(localHlc.counter == remoteHlc.counter, isTrue);
    });
  });
}

void compareHLC_Less_Equal_Greater_Tests(
  String Function(bool b) comStr,
  int m1,
  int m2,
  int c1,
  int c2,
  int s1,
  int s2,
  Hlc h1,
  Hlc h2,
) {
  void expectLessGreater(Hlc less, Hlc greater) {
    expect(less < greater, isTrue);
    expect(greater < less, isFalse);
    expect(less > greater, isFalse);
    expect(greater > less, isTrue);
  }

  void expectLessGreaterCompareTo(Hlc less, Hlc greater) {
    expect(less.compareTo(greater), -1);
    expect(less.compareToDESC(greater), 1);
    expect(greater.compareTo(less), 1);
    expect(greater.compareToDESC(less), -1);
  }

  test('LC - time: ${comStr(m1 == m2)} - counter: ${comStr(c1 == c2)} - sites: ${comStr(s1 == s2)}', () {
    if (m1 < m2) {
      expectLessGreater(h1, h2);
      expectLessGreaterCompareTo(h1, h2);
    } else if (m1 > m2) {
      expectLessGreater(h2, h1);
      expectLessGreaterCompareTo(h2, h1);
    } else if (m1 == m2) {
      if (c1 < c2) {
        expectLessGreater(h1, h2);
        expectLessGreaterCompareTo(h1, h2);
      } else if (c1 > c2) {
        expectLessGreater(h2, h1);
        expectLessGreaterCompareTo(h2, h1);
      } else if (c1 == c2) {
        if (s1 < s2) {
          expectLessGreater(h1, h2);
          expectLessGreaterCompareTo(h1, h2);
        } else if (s1 > s2) {
          expectLessGreater(h2, h1);
          expectLessGreaterCompareTo(h2, h1);
        } else if (s1 == s2) {
          expect(s1 == s2, isTrue);
          expect(s2 == s1, isTrue);

          expect(s1 != s2, isFalse);
          expect(s2 != s1, isFalse);

          expect(s1.compareTo(s2), 0);
          expect(s2.compareTo(s1), 0);
        } else {
          throw AssertionError('this should never happen');
        }
      } else {
        throw AssertionError('this should never happen');
      }
    } else {
      throw AssertionError('this should never happen');
    }
  });
}
