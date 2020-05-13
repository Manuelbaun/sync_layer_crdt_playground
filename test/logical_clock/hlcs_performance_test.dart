import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/timestamp/alternative/hlc.dart' as ts;
import 'package:sync_layer/timestamp/hybrid_logical_clock.dart';
import 'package:sync_layer/utils/measure.dart';
import 'package:test/test.dart';

final ms = DateTime(2020).millisecondsSinceEpoch;

void main() {
  print(ms);
  print(ms << 16);
  final hlcs0 = <ts.Hlc>[];
  final hlcs1 = <Hlc>[];

  measureExecution('test hlc0', () {
    for (var i = 0; i < 1000; i++) {
      final hlc = ts.Hlc(ms, 0, '1234');
      hlcs0.add(hlc);
    }

    hlcs0.sort();
  });

  measureExecution('test hlc1', () {
    for (var i = 0; i < 1000; i++) {
      final hlc = Hlc(ms, 0, 1234);
      hlcs1.add(hlc);
    }

    hlcs1.sort();
  });

  var b;

  var h;

  measureExecution('en decode', () {
    b = hlcs1.map((a) => msgpackEncode(a));
    h = b.map((bytes) => msgpackDecode(bytes)).toList();
  });

  var eq = false;

  test('De/Serialize', () {
    for (var i = 1; i < hlcs1.length; i++) {
      eq = hlcs1[i] == h[i];

      if (!eq) break;
    }

    expect(eq, isTrue);
  });
}
