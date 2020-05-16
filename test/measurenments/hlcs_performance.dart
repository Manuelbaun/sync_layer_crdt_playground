import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/alternatives/hlc.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/utils/measure.dart';

final ms = DateTime(2020).millisecondsSinceEpoch;

void main() {
  final hlcs1 = <HybridLogicalClock>[];
  final hlcs0 = <HybridLogicalClock_2>[];
  final ids = <Id>[];

  measureExecution('test HybridLogicalClock', () {
    for (var i = 0; i < 1000; i++) {
      final hlc = HybridLogicalClock(ms, 0);
      hlcs1.add(hlc);
    }
    hlcs1.sort();
  });

  measureExecution('test HybridLogicalClock_2', () {
    for (var i = 0; i < 1000; i++) {
      final hlc = HybridLogicalClock_2(ms, 0, '1234');
      hlcs0.add(hlc);
    }
    hlcs0.sort();
  });

  measureExecution('test HybridLogicalClock with Id', () {
    for (var i = 0; i < 1000; i++) {
      final hlc = HybridLogicalClock(ms, 0);
      final id = Id(hlc, 999);

      ids.add(id);
    }
    ids.sort();
  });

  var b;
  var h;

  measureExecution('en decode', () {
    b = hlcs1.map((a) => msgpackEncode(a));
    h = b.map((bytes) => msgpackDecode(bytes)).toList();
  });
}
