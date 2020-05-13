import 'package:sync_layer/crdts/atom.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/timestamp/index.dart';
import 'package:test/test.dart';

void main() {
  group('enDecoding', () {
    test('HLC', () {
      final a = Hlc(0, 1, 999);

      final b = msgpackEncode(a);
      final c = msgpackDecode(b);
      expect(a == c, isTrue);
    });

    test('LC', () {
      final a = LogicalTime(0, 1);

      final b = msgpackEncode(a);
      final c = msgpackDecode(b);
      expect(a == c, isTrue);
    });
  });

  group('atom wiht LC and HLC', () {
    test('encode atom with hlc', () {
      final clock = Hlc(DateTime.now().millisecondsSinceEpoch, 1, 999);
      final a1 = Atom(clock, 'Hello');

      final b1 = msgpackEncode(a1);
      final a2 = msgpackDecode(b1);

      expect(a1, a2);
    });
  });
}
