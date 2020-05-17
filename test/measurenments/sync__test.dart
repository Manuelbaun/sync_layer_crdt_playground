import 'dart:io';

import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/id_atom.dart';
import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/utils/measure.dart';

void main() {
  test1();

  /// 5, 1, 2, 2, 10, 1, 19 = 40
  final msg = [154825538227, 0, 2020, 77, '1asdf-5675', 2, 'Hallo mein Name ist'];
  final msg2 = [253489485221, 4, 2420, 1, '547513-2551', 3, 'Some other values'];
  final msg3 = [352155687227, 2, 4332, 3, '8989dad-41518-dv', 6, 'ok, jetzt wirds brenzlig'];
  final msg4 = [352153425222, 8, 123, 99, 'sas-41518-dv', 55, 's brenzlig'];

  final a1 = Atom(AtomId(HybridLogicalClock(msg[0], msg[1]), msg[2]), msg[3], msg[4], SyncableEntry(msg[5], msg[6]));

  final a2 =
      Atom(AtomId(HybridLogicalClock(msg2[0], msg2[1]), msg2[2]), msg2[3], msg2[4], SyncableEntry(msg2[5], msg2[6]));
  final a3 =
      Atom(AtomId(HybridLogicalClock(msg3[0], msg3[1]), msg3[2]), msg3[3], msg3[4], SyncableEntry(msg3[5], msg3[6]));

  final a4 =
      Atom(AtomId(HybridLogicalClock(msg4[0], msg4[1]), msg4[2]), msg4[3], msg4[4], SyncableEntry(msg4[5], msg4[6]));

  var time1 = 0;
  var time2 = 0;
  // print(b1.length);

  var m1;
  var m2;
  var b1;
  var b2;
  for (var i = 0; i < 1000; i++) {
    time2 += measureExecution('one', () {
      m1 = msgpackEncode([msg, msg2, msg3]);
      b1 = zlib.encode(m1);
    }, skipLog: true);

    time1 += measureExecution('two', () {
      m2 = msgpackEncode([a1, a2, a3]);
      b2 = zlib.encode(m2);
      // print(b2.length);
    }, skipLog: true);
  }

  print('msg: ${m1.length}- zlib: ${b1.length}');
  print('msg: ${m2.length}- zlib: ${b2.length}');

  print('${time1 / 1000} ms ');
  print('${time2 / 1000} ms ');

  time1 = 0;
  time2 = 0;
  for (var i = 0; i < 1000; i++) {
    time1 += measureExecution('two', () {
      final b2 = msgpackEncode([a1, a2, a3, a4]);
      zlib.encode(b2);
      // print(b2.length);
    }, skipLog: true);

    time2 += measureExecution('one', () {
      var b1;
      b1 = msgpackEncode([msg, msg2, msg3, msg4]);
      zlib.encode(b1);
    }, skipLog: true);
  }
  print('${time1 / 1000} ms ');
  print('${time2 / 1000} ms ');
}

void test1() {
  final list = [2, 'Hallo mein Name ist'];
  final map = {2: 'Hallo mein Name ist'};
  final snyc = SyncableEntry(list[0], list[1]);

  final b1 = msgpackEncode(list);
  final b2 = msgpackEncode(map);
  final b3 = msgpackEncode(snyc);

  print('done');
}
