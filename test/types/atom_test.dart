import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/atom.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/index.dart';
import 'package:test/test.dart';

void main() {
  group('simple Atom en/decode', () {
    test('LC', () {
      final a = Atom<String>(Id(LogicalClock(0), 1), data: 'hans');
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
    test('HLC', () {
      final a = Atom<int>(Id(HybridLogicalClock(0, 1), 1), data: 1);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);
      expect(a == c, isTrue);
    });
  });

  group('complex Atom en/decode', () {
    test('LC', () {
      final a = Atom<Value>(Id(LogicalClock(0), 1), data: Value(0, 'someidvalues1234', 1, 20));
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
    test('HLC', () {
      final a = Atom<Value>(Id(HybridLogicalClock(0, 1), 1020), data: Value(0, 'someidvalues1234', 1, 40));
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
  });

  group('complex Atom', () {
    test('Hlc Map', () {
      final m = {
        0: 'some type id',
        1: 'some long object id',
        2: 'some field id',
        3: 'some value',
      };

      final a = Atom<Map>(Id(HybridLogicalClock(0, 1), 1020), data: m);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
    test('HLC List ', () {
      final a = Atom<List>(Id(HybridLogicalClock(0, 1), 1020), data: ['hans', 120, 'peter']);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
  });
}
