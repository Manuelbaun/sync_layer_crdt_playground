import 'package:sync_layer/basic/timestamp/hlc.dart' as ts;
import 'package:sync_layer/basic/timestamp/hybrid_logical_clock.dart';
import 'package:sync_layer/utils/measure.dart';

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

  final hlcs1Conv = [];
  final bytes = [];
  measureExecution('test hlc1 serialize', () {
    for (final h in hlcs1) {
      bytes.add(h.toBytes());
    }
  });

  measureExecution('test hlc1 deserialize', () {
    for (final b in bytes) {
      hlcs1Conv.add(Hlc.fromBytes(b));
    }
  });

  final h = [];
  final h2 = [];
  final b = [];

  measureExecution('all together', () {
    for (var i = 0; i < 1000; i++) {
      h.add(Hlc(ms, 0, 1234));
    }
    hlcs1.sort();

    for (final h in hlcs1) {
      b.add(h.toBytes());
    }

    for (final b in b) {
      h2.add(Hlc.fromBytes(b));
    }
  });
  var eq = false;
  for (var i = 1; i < hlcs1.length; i++) {
    eq = h[i] == h2[i];

    if (!eq) break;
  }

  print(eq);
  // bytes.forEach((b) => print(b.length));
}
