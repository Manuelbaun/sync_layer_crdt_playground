import 'package:sync_layer/crdts/causal_tree/index.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/logical_clock.dart';

import 'package:test/test.dart';

void main() {
  final id0 = Id(LogicalClock(0), 2);

  final id1 = Id(LogicalClock(0), 10);
  final id3 = Id(LogicalClock(1), 10);
  final id4 = Id(LogicalClock(0), 11);

  group('basic', () {
    test('toString', () {
      final e = CausalEntry(Id(LogicalClock(0), 2));
      final e2 = CausalEntry(Id(LogicalClock(0), 2), cause: Id(LogicalClock(1), 3));
      final e3 = CausalEntry(Id(LogicalClock(0), 2), cause: Id(LogicalClock(1), 3), data: 'hans');
      expect(e.toString(), 'S2@T0->null : null');
      expect(e2.toString(), 'S2@T0->S3@T1 : null');
      expect(e3.toString(), 'S2@T0->S3@T1 : hans');
    });

    test('missing id error', () {
      try {
        final e = CausalEntry(null);
      } catch (e) {
        expect(e.message, 'id must be provided');
      }
    });
  });

  group('comparing', () {
    test('causal siblings ', () {
      final root = CausalEntry(id1);

      final e1 = CausalEntry(id3, cause: id1);
      final e2 = CausalEntry(id4, cause: id1);

      expect(e1.isSibling(e2), isTrue);
      expect(e1.relatesTo(e2), RelationShip.Sibling);
    });

    test('Relates to', () {
      final root = CausalEntry(id1);
      final root2 = CausalEntry(id0);

      final e1 = CausalEntry(id3, cause: id1);
      final e2 = CausalEntry(id4, cause: id1);

      expect(e1.relatesTo(root), RelationShip.CausalRight);
      expect(e2.relatesTo(root), RelationShip.CausalRight);
      expect(root.relatesTo(e1), RelationShip.CausalLeft);
      expect(root.relatesTo(e2), RelationShip.CausalLeft);
      expect(root.relatesTo(root), RelationShip.Identical);
      expect(root.relatesTo(root2), RelationShip.Unknown);
    });

    test('is Left Of, when ', () {
      final root = CausalEntry(Id(LogicalClock(0), 10));
      final e1 = CausalEntry(Id(LogicalClock(1), 10), cause: root.id);
      final e2 = CausalEntry(Id(LogicalClock(1), 11), cause: root.id);

      // must be siblings
      expect(e1.isSibling(e2), isTrue);

      // greater site by same time is left of, only when same cause
      expect(e2.isLeftOf(e1), isTrue);
      expect(e1.isLeftOf(e2), isFalse);
    });
  });

  /// TODO: with HLC
}
