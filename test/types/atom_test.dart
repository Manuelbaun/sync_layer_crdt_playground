import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/atom.dart';

import 'package:sync_layer/types/index.dart';
import 'package:test/test.dart';

void main() {
  group('simple Atom en/decode', () {
    test('HLC', () {
      final a = Atom<String>(Id(HybridLogicalClock(0), 1), 0, 'objectId', 'hans');
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);
      expect(a == c, isTrue);
    });
  });

  group('complex Atom en/decode', () {
    test('HLC', () {
      final a = Atom<SyncableEntry>(Id(HybridLogicalClock(0, 1), 1020), 0, 'someidvalues1234', SyncableEntry(1, 40));
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

      final a = Atom<Map>(Id(HybridLogicalClock(0, 1), 1020), 0, 'someidvalues1234', m);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
    test('HLC List ', () {
      final a = Atom<List>(Id(HybridLogicalClock(0, 1), 1020), 0, 'someidvalues1234', ['hans', 120, 'peter']);
      final b = msgpackEncode(a);
      final c = msgpackDecode(b);

      expect(a == c, isTrue);
    });
  });
}
