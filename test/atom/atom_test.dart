import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'package:test/test.dart';

void main() {
  group('simple Atom en/decode', () {
    test('LC', () {
      final a = Atom<String>(LogicalTime(0, 1), 'hans');
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
    test('HLC', () {
      final a = Atom<int>(Hlc(0, 1, 999), 1);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);
      expect(a == c, isTrue);
    });
  });

  group('complex Atom en/decode', () {
    test('LC', () {
      final a = Atom<Value>(LogicalTime(0, 1), Value(0, 'someidvalues1234', 1, 20));
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
    test('HLC', () {
      final a = Atom<Value>(Hlc(0, 1, 1020), Value(0, 'someidvalues1234', 1, 40));
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

      final a = Atom<Map>(Hlc(0, 1, 1020), m);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
    test('HLC List ', () {
      final a = Atom<List>(Hlc(0, 1, 1020), ['hans', 120, 'peter']);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
  });
}
