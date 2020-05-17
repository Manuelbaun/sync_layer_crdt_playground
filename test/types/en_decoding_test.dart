import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';
import 'package:sync_layer/types/id_atom.dart';
import 'package:sync_layer/types/index.dart';
import 'package:test/test.dart';

void main() {
  group('enDecoding', () {
    test('HLC', () {
      final a = HybridLogicalClock(0, 1);

      final b = msgpackEncode(a);
      final c = msgpackDecode(b);
      expect(a == c, isTrue);
    });

    test('LC', () {
      final a = LogicalClock(0);

      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
  });

  group('atom wiht LC and HLC', () {
    test('encode atom with HLC', () {
      final clock = HybridLogicalClock(DateTime.now().millisecondsSinceEpoch, 1);
      final cl = msgpackEncode(clock);

      print(cl);

      final a1 = Atom<Map>(AtomId(HybridLogicalClock(0, 1), 1020), 0, 'someidvalues1234', {1: 'data'});

      final b1 = msgpackEncode(a1);
      final a2 = msgpackDecode(b1);
      print(b1);
      print(b1.length);
      print(a2);


      expect(a1, a2);
    });
  });
}
