import 'package:sync_layer/crdts/causal_tree/id.dart';
import 'package:sync_layer/crdts/causal_tree/lc2.dart';
import 'package:test/test.dart';

void main() {
  final id1 = Id(LogicalClock(0), 10);
  final id2 = Id(LogicalClock(0), 10);
  final id3 = Id(LogicalClock(1), 10);
  final id4 = Id(LogicalClock(0), 11);

  group('basic', () {
    test('Same Time, same Site', () {
      expect(id1 == id2, isTrue);
      expect(id2 == id3, isFalse);
      expect(id2 == id4, isFalse);
      expect(id3 == id4, isFalse);
    });

    test('Missing timestamp', () {
      try {
        Id(null, 0);
      } catch (e) {
        expect(e.message, 'ts cant be null');
      }
    });

    test('Missing site', () {
      try {
        Id(LogicalClock(0), null);
      } catch (e) {
        expect(e.message, 'site cant be null');
      }
    });
  });

  /// TODO: with HLC
}
