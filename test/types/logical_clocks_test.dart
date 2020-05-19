import 'package:sync_layer/types/hybrid_logical_clock.dart';
import 'package:sync_layer/types/logical_clock.dart';
import 'package:test/test.dart';

void main() {
  group('LogicalClock', () {
    test('Factories', () {
      final lc = LogicalClock(0);
      final lc2 = LogicalClock.send(lc);
      final lc3 = LogicalClock.recv(lc2, lc);
      final lc4 = LogicalClock.fromLogical(5);

      expect(lc.logicalTime, 0);
      expect(lc2.logicalTime, 1);
      expect(lc3.logicalTime, 1);
      expect(lc4.logicalTime, 5);
    });

    test('comparison', () {
      final lc = LogicalClock(0);
      final other = LogicalClock(0);
      final lc2 = LogicalClock.send(lc);
      final lc3 = LogicalClock.recv(other, lc2);

      expect(lc < lc2, isTrue);
      expect(lc < lc3, isTrue);
      expect(lc2 < lc3, isFalse);

      expect(lc <= lc2, isTrue);
      expect(lc <= lc3, isTrue);
      expect(lc2 <= lc3, isTrue);

      expect(lc3 > lc2, isFalse);
      expect(lc3 > lc, isTrue);
      expect(lc2 > lc, isTrue);

      expect(lc3 >= lc2, isTrue);
      expect(lc3 >= lc, isTrue);
      expect(lc2 >= lc, isTrue);

      expect(lc == other, isTrue);
      expect(lc <= other, isTrue);
      expect(lc >= other, isTrue);

      expect(lc2 == lc3, isTrue);
    });

    test('subtract', () {
      final lc = LogicalClock(0);
      final other = LogicalClock(0);
      final lc2 = LogicalClock.send(lc);
      final lc3 = LogicalClock.recv(lc2, lc);

      expect(lc - other, 0);
      expect(lc3 - lc2, 0);
      expect(lc3 - lc, 1);
    });
  });

  // hybridLogicalClockTests();
}

void hybridLogicalClockTests() {
  var testHlc = HybridLogicalClock(1579633503119, 42);
  group('Compare < <= =  >= >', () {
    // 3^6 iteration => 729
    String comStr(bool b) => b ? 'equal'.padRight(10, ' ') : 'different'.padRight(10, ' ');

    final mss = [1579633503119, 1579633503119 + 100, 1579633503119 + 200];
    final counter = [0, 1, 2];

    var i = 1;
    for (var m1 in mss) {
      for (var m2 in mss) {
        for (var c1 in counter) {
          for (var c2 in counter) {
            // run tests
            final h1 = HybridLogicalClock(m1, c1);
            final h2 = HybridLogicalClock(m2, c2);
            i++;
          }
        }
      }
    }

    print('Compare < <= = >= > Tests $i');
  });
  group('Compare Subtract diffs', () {
    final mss = [1579633503119, 1579633503120, 1579633503121];
    final counter = [0, 1, 2];
    var i = 1;
    test('Compare Subtract HLC', () {
      for (var m1 in mss) {
        for (var m2 in mss) {
          for (var c1 in counter) {
            for (var c2 in counter) {
              i++;
              // run tests
              final h1 = HybridLogicalClock(m1, c1);
              final h2 = HybridLogicalClock(m2, c2);
              final md1 = m1 - m2;

              final cd1 = c1 - c2;
              final res = md1 << 16 | cd1;
              // todo: think again, how subtraction should work with hlc
              final sub = h1 - h2;
              expect(sub == res, isTrue);
            }
          }
        }
      }
    });
    print('Compare Subtract diffs Tests $i');
  });

  group('Comparison', () {
    test('Equality', () {
      var hlc = HybridLogicalClock(1579633503119, 42);
      expect(testHlc, hlc);
    });

    test('Equality with different nodes', () {
      var hlc = HybridLogicalClock(1579633503119, 42);
      expect(testHlc, hlc);
    });

    test('Less than millis', () {
      var hlc = HybridLogicalClock(1579733503119, 42);
      expect(testHlc < hlc, isTrue);
    });

    test('Less than counter', () {
      var hlc = HybridLogicalClock(1579633503119, 43);
      expect(testHlc < hlc, isTrue);
    });

    test('Fail less than if equals', () {
      var hlc = HybridLogicalClock(1579633503119, 42);
      expect(testHlc < hlc, isFalse);
    });

    test('Fail less than if millis and counter disagree', () {
      var hlc = HybridLogicalClock(1579533503119, 43);
      expect(testHlc < hlc, isFalse);
    });
  });

  group('String operations', () {
    test('hlc to string', () {
      expect(testHlc.toString(), '16fc97e6b8f-2a');
    });

    test('Parse hlc', () {
      expect(HybridLogicalClock.parse('16fc97e6b8f-2a'), testHlc);
    });
  });

  group('Send', () {
    test('Send before', () {
      var hlc = HybridLogicalClock.send(testHlc, 1579633503110);

      final r = isNot(testHlc);
      expect(hlc, r);
      expect(hlc.toString(), '16fc97e6b8f-2b');
    });

    test('Send simultaneous', () {
      var hlc = HybridLogicalClock.send(testHlc, 1579633503119);
      expect(hlc, isNot(testHlc));
      expect(hlc.toString(), '16fc97e6b8f-2b');
    });

    test('Send later', () {
      var hlc = HybridLogicalClock.send(testHlc, 1579733503119);
      expect(hlc, HybridLogicalClock(1579733503119, 0));
    });
  });

  group('Receive', () {
    test('Receive before', () {
      var remoteHlc = HybridLogicalClock(1579633503110, 0);
      var hlc = HybridLogicalClock.recv(testHlc, remoteHlc, 1579633503119);
      expect(hlc, isNot(equals(testHlc)));
    });

    test('Receive simultaneous', () {
      var remoteHlc = HybridLogicalClock(1579633503119, 0);
      var hlc = HybridLogicalClock.recv(testHlc, remoteHlc, 1579633503119);
      expect(hlc, isNot(testHlc));
    });

    test('Receive after', () {
      var remoteHlc = HybridLogicalClock(1579633503119, 0);
      var hlc = HybridLogicalClock.recv(testHlc, remoteHlc, 1579633503129);
      expect(hlc, isNot(testHlc));
    });
  });

  group('Clock drifts', () {
    final date1 = DateTime(2020, 3, 0);
    final date2 = DateTime(2020, 4, 0);
    final local = DateTime(2020, 5, 0);

    final hlcD1 = HybridLogicalClock(date1.millisecondsSinceEpoch, 0);
    final hlcD2 = HybridLogicalClock(date2.millisecondsSinceEpoch, 0);
    final hlcD3 = HybridLogicalClock(local.millisecondsSinceEpoch, 0);

    test('Receive Ts in total time order', () {
      // init
      final hlc1 = HybridLogicalClock.recv(hlcD1, hlcD1);
      // recieve first
      final hlc2 = HybridLogicalClock.recv(hlc1, hlcD2);
      // recieves second
      final hlc3 = HybridLogicalClock.recv(hlc2, hlcD3);

      expect(hlc1 < hlc2, isTrue);
      expect(hlc2 < hlc3, isTrue);
    });

    test('Receive ', () {
      // init

      final newLocal1 = HybridLogicalClock.recv(hlcD1, hlcD1);
      // recieves second
      final newLocal2 = HybridLogicalClock.recv(newLocal1, hlcD3);
      // recieve first
      final newLocal3 = HybridLogicalClock.recv(newLocal2, hlcD2);

      expect(newLocal1 < newLocal2, isTrue);
      expect(newLocal1 < newLocal3, isTrue);
      expect(newLocal2 < newLocal3, isTrue);
    });
  });
}
