import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/timestamp/index.dart';
import 'package:test/test.dart';

void main() {
  group('basic', () {
    test('to string', () {
      final lc = LogicalTime(0, 123);
      expect(lc.toString(), '0-7b');
    });
    test('to string2', () {
      final lc = LogicalTime(0, 123);
      expect(lc.toRON(), 'S7b@T0');
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
}
