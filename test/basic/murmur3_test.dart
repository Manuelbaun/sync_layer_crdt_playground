import 'dart:isolate';
import 'dart:math';

import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/utils/measure.dart';

final rand1 = Random(0);
final rand2 = Random(9999);
final rand3 = Random(1111);

int randomInt(int max, {int min = 0}) => max == min ? max : rand1.nextInt(max - min) + min;
int randomInt2(int max, {int min = 0}) => max == min ? max : rand2.nextInt(max - min) + min;
int randomInt3(int max, {int min = 0}) => max == min ? max : rand3.nextInt(max - min) + min;

@pragma('vm:prefer-inline')
int ror64(int v, int r) {
  return (v >> r) | (v << (64 - r));
}

int rrxmrrxmsx_0(int v) {
  v ^= ror64(v, 25) ^ ror64(v, 50);
  v *= 0xA24BAED4963EE407; //UL;
  v ^= ror64(v, 24) ^ ror64(v, 49);
  v *= 0x9FB21C651E98DF25; //UL;
  return v ^ v >> 28;
}

Isolate isolate1;
Isolate isolate2;
Isolate isolate3;
Isolate isolate4;
final min = (DateTime(2020).millisecondsSinceEpoch / 1000).floor();
final max = (DateTime(2040).millisecondsSinceEpoch / 1000).floor();

const test_size = 100000;

List<List<int>> ids;

void main(List<String> args) async {
  var size = args.isNotEmpty ? int.parse(args[0]) : test_size;

  measureExecution('generate', () {
    ids = List.generate(size, (i) {
      final counter = randomInt3(0xffff, min: 0);
      final ts = randomInt(max, min: min) << 16 | counter;

      final site = randomInt2(max, min: min);
      return [ts, site];
    });
  });

  print('Run $size');

  run1();
  run2();
  run3();
  run4();
}

void printing(String name, int micros, int counter) {
  name = name.padRight(20, ' ');
  List ll = '${micros / 1000}'.split('.');

  var time = '';
  time += ll[0].padLeft(5, ' ');
  time += '.';
  time += ll[1].padRight(3, '0');
  time += ' ms';

  final coll = '${counter}'.padLeft(5, ' ') + ' collision';

  print('$name : $time : $coll');
}

void run1() {
  var counter = 0;
  final has = <int>{};

  var micros = measureExecution('Hash MurmurV3', () {
    for (final h in ids) {
      final hash = MurmurHashV3('${h[1]}-${h[0]}');

      if (!has.add(hash)) counter++;
    }
  }, skipLog: true);

  printing('MurmurV3 32bit', micros, counter);
}

void run2() {
  var counter = 0;
  final has = <int>{};

  var micros = measureExecution('Hash Dart hascode', () {
    for (final h in ids) {
      if (!has.add('${h[1]}-${h[0]}'.hashCode)) counter++;
    }
  }, skipLog: true);

  printing('Dart hascode', micros, counter);
}

void run3() {
  var counter = 0;
  final has = <int>{};

  var micros = measureExecution('Hash Numbers xor', () {
    for (final h in ids) {
      final hash = h[0] ^ h[1];
      if (!has.add(hash)) counter++;
    }
  }, skipLog: true);

  printing('Numbers xor', micros, counter);
}

void run4() {
  var counter = 0;
  var micros = measureExecution('Hash rrxmrrxmsx_0', () {
    final has = <int>{};

    for (final h in ids) {
      final hash = rrxmrrxmsx_0(h[0] ^ h[1]);
      if (!has.add(hash)) counter++;
    }
  }, skipLog: true);

  printing('rrxmrrxmsx_0', micros, counter);
}
