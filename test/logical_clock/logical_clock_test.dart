import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'package:test/test.dart';

void main() {
  group('basic', () {
    test('to string', () {
      final lc = LogicalTime(0, 123);
      expect(lc.toString(), '0-7b');
    });
    test('to string2', () {
      final lc = LogicalTime(0, 123);
      expect(lc.toStringRON(), 'S7b@T0');
    });

    test('comp == not equal: same site', () {
      final t1 = LogicalTime(0, 123);
      final t2 = LogicalTime(10, 123);

      expect(t1 == t2, isFalse);
    });

    test('comp == not equal: same time not same site', () {
      final t1 = LogicalTime(10, 122);
      final t2 = LogicalTime(10, 123);

      expect(t1 == t2, isFalse);
    });

    test('comp == equal: same time, same site', () {
      final t1 = LogicalTime(0, 123);
      final t2 = LogicalTime(0, 123);

      expect(t1 == t2, isTrue);
    });

    test('comp < same site', () {
      final t1 = LogicalTime(0, 123);
      final t2 = LogicalTime(1, 123);

      expect(t1 < t2, isTrue);
    });

    test('comp > same site', () {
      final t1 = LogicalTime(0, 123);
      final t2 = LogicalTime(1, 123);

      expect(t2 > t1, isTrue);
    });

    test('comp < diffenent site', () {
      final t1 = LogicalTime(0, 123);
      final t2 = LogicalTime(1, 123);

      expect(t1 < t2, isTrue);
    });

    test('comp > different site', () {
      final t1 = LogicalTime(0, 123);
      final t2 = LogicalTime(1, 124);

      expect(t2 > t1, isTrue);
    });

    test('comp < same time, diffenent site', () {
      final t1 = LogicalTime(1, 122);
      final t2 = LogicalTime(1, 123);

      expect(t1 < t2, isTrue);
    });

    test('comp > different site', () {
      final t1 = LogicalTime(1, 122);
      final t2 = LogicalTime(1, 123);

      expect(t2 > t1, isTrue);
    });
  });

  group('hash', () {
    test('MurmurV3 hashcode', () {
      final t1 = LogicalTime(1, 122);
      final hashcode = MurmurHashV3('${1.toRadixString(16)}-${122.toRadixString(16)}');
      expect(t1.hashCode, hashcode);
    });
  });

  group('send recv', () {
    test('send increment', () {
      final t1 = LogicalTime(1, 122);
      final t2 = LogicalTime.send(t1);

      expect(t2.toString(), '2-7a');
    });
  });

  group('Comparing Equal', () {
    String comStr(bool b) => b ? 'same'.padRight(10, ' ') : 'different'.padRight(10, ' ');
    for (var t1 in [0, 1]) {
      for (var t2 in [0, 1]) {
        for (var site1 in [111, 222]) {
          for (var site2 in [111, 222]) {
            final c1 = LogicalTime(t1, site1);
            final c2 = LogicalTime(t2, site2);

            test('LC - time: ${comStr(t1 == t2)} - sites : ${comStr(site1 == site2)}', () {
              if (t1 == t2 && site1 == site2) {
                expect(c1 == c2, isTrue);
                expect(c2 == c1, isTrue);

                expect(c1 != c2, isFalse);
                expect(c2 != c1, isFalse);
              } else {
                expect(c1 == c2, isFalse);
                expect(c2 == c1, isFalse);

                expect(c1 != c2, isTrue);
                expect(c2 != c1, isTrue);
              }
            });
          }
        }
      }
    }
  });

  final times = [0, 1, 2];
  final sites = [111, 222, 333];

  group('Comparing < > less and greater', () {
    String comStr(bool b) => b ? 'same'.padRight(10, ' ') : 'different'.padRight(10, ' ');

    for (var t1 in times) {
      for (var t2 in times) {
        for (var site1 in sites) {
          for (var site2 in sites) {
            final c1 = LogicalTime(t1, site1);
            final c2 = LogicalTime(t2, site2);

            test('LC - time: ${comStr(t1 == t2)} - sites : ${comStr(site1 == site2)}', () {
              if (t1 < t2) {
                expect(c1 < c2, isTrue);
                expect(c2 > c1, isTrue);

                expect(c1.compareTo(c2), -1);
                expect(c1.compareToDESC(c2), 1);
                expect(c2.compareTo(c1), 1);
                expect(c2.compareToDESC(c1), -1);
              } else if (t1 == t2) {
                if (site1 < site2) {
                  expect(c1 < c2, isTrue);
                  expect(c2 > c1, isTrue);

                  expect(c1.compareTo(c2), -1);
                  expect(c1.compareToDESC(c2), 1);
                  expect(c2.compareTo(c1), 1);
                  expect(c2.compareToDESC(c1), -1);
                }
                if (site1 > site2) {
                  expect(c1 > c2, isTrue);
                  expect(c2 < c1, isTrue);

                  expect(c1.compareTo(c2), 1);
                  expect(c1.compareToDESC(c2), -1);
                  expect(c2.compareTo(c1), -1);
                  expect(c2.compareToDESC(c1), 1);
                }
                if (site1 == site2) {
                  expect(c1 == c2, isTrue);
                  expect(c2 == c1, isTrue);

                  expect(c1 != c2, isFalse);
                  expect(c2 != c1, isFalse);

                  expect(c1.compareTo(c2), 0);
                  expect(c1.compareToDESC(c2), 0);
                  expect(c2.compareTo(c1), 0);
                  expect(c2.compareToDESC(c1), 0);
                }
              } else if (t1 > t2) {
                expect(c1 > c2, isTrue);
                expect(c2 < c1, isTrue);

                expect(c1.compareTo(c2), 1);
                expect(c1.compareToDESC(c2), -1);
                expect(c2.compareTo(c1), -1);
                expect(c2.compareToDESC(c1), 1);
              } else {
                expect('this should not be happen', false);
              }
            });
          }
        }
      }
    }
  });

  group('Comparing diffing', () {
    String comStr(bool b) => b ? 'same'.padRight(10, ' ') : 'different'.padRight(10, ' ');
    // final times = [0, 1, 2];
    // final sites = [111, 222, 333];
    for (var t1 in times) {
      for (var t2 in times) {
        for (var site1 in sites) {
          for (var site2 in sites) {
            final c1 = LogicalTime(t1, site1);
            final c2 = LogicalTime(t2, site2);

            test('LC - time: ${comStr(t1 == t2)} - sites : ${comStr(site1 == site2)}', () {
              final res = (c1 - c2)[0];
              final res2 = (c2 - c1)[0];

              if (t1 < t2) {
                expect(res, t1 - t2);
                expect(res2, t2 - t1);
              } else if (t1 == t2) {
                expect(res, 0);
                expect(res2, 0);
              } else if (t1 > t2) {
                expect(res, t1 - t2);
                expect(res2, t2 - t1);
              } else {
                expect('this should not be happen', false);
              }
            });
          }
        }
      }
    }
  });
}
