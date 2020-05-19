import 'dart:io';

import 'package:sync_layer/crdts/causal_tree/index.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/logical_clock.dart';

import 'package:test/test.dart';

void main() {
  final id0 = Id(LogicalClock(0), 2);

  final id1 = Id(LogicalClock(0), 10);
  final id3 = Id(LogicalClock(1), 10);
  final id4 = Id(LogicalClock(0), 11);

  final e1 = CausalEntry(Id(LogicalClock(33), 2));
  final e2 = CausalEntry(Id(LogicalClock(0), 2), cause: Id(LogicalClock(1), 3));
  final e3 = CausalEntry(Id(LogicalClock(33), 25), cause: Id(LogicalClock(20), 3), data: 'hans');
  final e4b = msgpackEncode(e3);
  print(e4b.length);
  print(msgpackDecode(e4b));
  print(e3);

  print('....');
  final e1b = msgpackEncode([e1.id.ts, e1.id.site, e1.cause?.ts, e1.cause?.site, e1.data]);
  final e2b = msgpackEncode([e2.id.ts, e2.id.site, e2.cause?.ts, e2.cause?.site, e2.data]);
  final e3b = msgpackEncode([e3.id.ts, e3.id.site, e3.cause?.ts, e3.cause?.site, e3.data]);
  print(e1b.length);
  print(e2b.length);
  print(e3b.length);

  print(zlib.encode(e1b).length);
  print(zlib.encode(e2b).length);
  print(zlib.encode(e3b).length);
}
// 13
// ...
// 8
// 10
// 14
// 16
// 18
// 22
