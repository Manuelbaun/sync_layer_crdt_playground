import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/sync/index.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/utils/measure.dart';

import 'dao.dart';

/// --------------------------------------------------------------
/// --------------------------------------------------------------
/// --------------------------------------------------------------
// create protocol class
final rand = Random(8);
final nodeID = rand.nextInt(999999);
final nodeIDRemote = rand.nextInt(999999);
var PATH = Directory.current.path + '\\';
final createOBjects = 100;

IOSink getFiles(String fileName) {
  final newPath = PATH + 'measurements\\';
  final dir = Directory(newPath)..createSync(recursive: true);
  final pp = newPath + '$fileName.csv';

  final exist = FileSystemEntity.typeSync(pp) != FileSystemEntityType.notFound;

  final file = File(pp).openWrite(mode: FileMode.append);

  if (!exist) {
    file.write('items;time[us];ticks;node\n');
  }

  return file;
}

bool compare(SyncDao local, SyncDao remote) {
  final localState = local.syn.getState();
  final remoteState = remote.syn.getState();
  final diff = localState.getDifferences(remoteState);

  final lo_map = local.map.allObjects();
  final ro_map = remote.map.allObjects();
  final lo_map_s = lo_map.toString();
  final ro_map_s = ro_map.toString();
  final mapString = lo_map_s == ro_map_s;

  final lo_arr = local.array.allObjects().map((e) => e.values);
  final ro_arr = remote.array.allObjects().map((e) => e.values);
  final lo_arr_s = lo_arr.toString();
  final ro_arr_s = ro_arr.toString();

  final arrString = lo_arr_s == ro_arr_s;

  final l_ser = msgpackEncode(local.syn.atomCache.allAtoms);
  final r_ser = msgpackEncode(remote.syn.atomCache.allAtoms);
  final ss = l_ser.toString();

  /// compare all bools
  final equal = mapString && arrString && lo_map.length == ro_map.length && ss == r_ser.toString();
  final noDiff = diff.local.isEmpty && diff.remote.isEmpty;

  return equal && noDiff;
}

var bools = <bool>[];
var res = false;
void main(List<String> arguments) async {
  if (!PATH.contains('experiments')) PATH += 'experiments\\';

  await ep1_map_set_key_value();
  await ep2_ct_push();
  await ep3_ct_insert_at_0();
  await ep4_ct_insert_random();
  // ct_ep5();
}

Future ep1_map_set_key_value() async {
  final file = getFiles('map_e1');

  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);

    await exp(
      file: file,
      items: items,
      local: local,
      remote: remote,
      createObjects: createOBjects,
      type: 'Map',
      skipLog: true,
      useticks: true,
      preFunc: (i) => local.map.create(),
      func: (map) {
        (map as SyncableMap).transact((ref) {
          for (var j = 0; j < items; j++) {
            ref[j] = itemsList[j];
          }
        });
        return map;
      },
    );

    for (var i = 0; i < createOBjects; i++) {
      final s = Stopwatch()..start();
      final map = <dynamic, dynamic>{};
      map['id'] = local.syn.generateNewObjectIds();

      for (var j = 0; j < items; j++) {
        map[j] = itemsList[j];
      }
      s.stop();

      file.write('$items;${s.elapsedMicroseconds};${s.elapsedTicks};native\n');
    }

    bools.add(compare(local, remote));
  }

  await file.close();
}

Future ep2_ct_push() async {
  final file = getFiles('ct_e1');
  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);

    await exp(
      file: file,
      items: items,
      local: local,
      remote: remote,
      type: 'CT',
      createObjects: createOBjects,
      preFunc: (i) => local.array.create(),
      func: (ct) {
        (ct as SyncArray).transact((ref) {
          for (var i = 0; i < items; i++) {
            ref.push(itemsList[i]);
          }
        });

        return ct;
      },
    );

    for (var i = 0; i < createOBjects; i++) {
      final s = Stopwatch()..start();
      final item = [];
      item.add(local.syn.generateNewObjectIds());

      for (var j = 0; j < items; j++) {
        item.add(itemsList[j]);
      }
      s.stop();

      file.write('$items;${s.elapsedMicroseconds};${s.elapsedTicks};native\n');
    }

    bools.add(compare(local, remote));
  }
  await file.close();
}

Future ep3_ct_insert_at_0() async {
  final file = getFiles('ct_e2');

  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);
    await exp(
      file: file,
      items: items,
      local: local,
      remote: remote,
      createObjects: createOBjects,
      type: 'CT',
      preFunc: (i) => local.array.create(),
      func: (ct) {
        (ct as SyncArray).transact((ref) {
          for (var i = 0; i < items; i++) {
            ref.insert(0, itemsList[i]);
          }
        });

        return ct;
      },
    );

    for (var i = 0; i < createOBjects; i++) {
      final s = Stopwatch()..start();
      final item = [];
      item.insert(0, local.syn.generateNewObjectIds());

      for (var j = 0; j < items; j++) {
        item.insert(0, itemsList[j]);
      }
      s.stop();

      file.write('$items;${s.elapsedMicroseconds};${s.elapsedTicks};native\n');
    }

    bools.add(compare(local, remote));
  }

  await file.close();
}

Future ep4_ct_insert_random() async {
  final file = getFiles('ct_e3');

  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);
    final pos = List.generate(items, (i) => i > 1 ? rand.nextInt(i - 1) : 0);

    await exp(
      file: file,
      items: items,
      local: local,
      remote: remote,
      type: 'CT',
      createObjects: createOBjects,
      preFunc: (i) => local.array.create(),
      func: (ct) {
        (ct as SyncArray).transact((ref) {
          for (var i = 0; i < items; i++) {
            ref.insert(pos[i], itemsList[i]);
          }
        });

        return ct;
      },
    );

    for (var i = 0; i < createOBjects; i++) {
      final s = Stopwatch()..start();
      final item = [];
      item.insert(0, local.syn.generateNewObjectIds());

      for (var j = 0; j < items; j++) {
        item.insert(pos[j], itemsList[j]);
      }
      s.stop();

      file.write('$items;${s.elapsedMicroseconds};${s.elapsedTicks};native\n');
    }

    bools.add(compare(local, remote));
  }

  res = bools.every((e) => e == true);
  print(res);
  await file.close();
}

/// Measure push and insert random position
void ct_ep5() {
  final l = SyncDao(nodeID);
  final l2 = SyncDao(nodeID);
  final r = SyncDao(nodeID);
  final r2 = SyncDao(nodeID);

  final ct_push = l.array.create('push_op');
  final ct_insert_random = l2.array.create('random_insert');
  final values_us = <int, String>{};

  final items = 10000;
  final skipLog = true;

  measureExecution('local [push] $items', () {
    for (var i = 0; i < items; i++) {
      final us1 = measureExecution('local push atom', () {
        ct_push.push('a');
      }, skipLog: skipLog);
      values_us[i] = '$us1;';
    }
  });

  // full copy!!
  final atoms = l.syn.atomCache.allAtoms.map((a) => msgpackDecode(msgpackEncode(a)));

  measureExecution('remote [push] $items', () {
    var i = 0;
    for (var a in atoms) {
      final us1 = measureExecution('remote pushed atom', () {
        r.syn.applyRemoteAtoms([a]);
      }, skipLog: skipLog);
      values_us[i++] += '$us1;';
    }
  });

  measureExecution('local [insert rand] $items', () {
    for (var i = 0; i < items; i++) {
      final us2 = measureExecution('local rand insert atom', () {
        var pos = rand.nextInt(i < 1 ? 1 : i);
        ct_insert_random.insert(pos, 'a');
      }, skipLog: skipLog);

      values_us[i] += '$us2;';
    }
  });

  final atoms2 = l2.syn.atomCache.allAtoms.map((a) => msgpackDecode(msgpackEncode(a)));
  // full copy!!
  measureExecution('remote [insert rand] $items', () {
    var i = 0;

    for (var a in atoms2) {
      final us1 = measureExecution('remote rand insert atom', () {
        r2.syn.applyRemoteAtoms([a]);
      }, skipLog: skipLog);
      values_us[i++] += '$us1';
    }
  });

  final file = File(PATH + 'measurements\\' 'ct_ep5.csv').openWrite(mode: FileMode.append);
  file.write('index;l_push;r_push;l_rand;r_rand\n');
  values_us.forEach((i, v) => file.write('$i;$v\n'));
  file.close();
}

void exp({
  int items,
  String type,
  IOSink file,
  SyncDao local,
  SyncDao remote,
  int createObjects = 100,
  bool skipLog = true,
  bool useticks = false,
  SyncableBase Function(SyncableBase) func,
  SyncableBase Function(int) preFunc,
}) async {
  final completers = <String, Completer>{};

  local.syn.atomStream.listen((a) {
    final b = msgpackEncode(a);
    final aa = List<AtomBase>.from(msgpackDecode(b));

    String id;

    final s = Stopwatch()..start();

    id = aa[0].objectId;
    remote.syn.applyRemoteAtoms(aa);
    s.stop();

    file.write('$items;${s.elapsedMicroseconds};${s.elapsedTicks};remote\n');
    completers[id].complete();
  });

  for (var i = 0; i < createObjects; i++) {
    final item = preFunc(i);
    final s = Stopwatch()..start();
    func(item);
    s.stop();

    file.write('$items;${s.elapsedMicroseconds};${s.elapsedTicks};local\n');
    completers[item.id] = Completer();
  }

  await Future.wait(completers.values.map((c) => c.future));
}

var itemsList = [
  'Peter Pan',
  'My first todo title',
  'A very very long string, that should be inserted.',
  25,
  0xffffffffffffffff,
  {
    'country': 'Germany',
    'city': 'Berlin',
    'street': 'Platz der Republik',
    'number': 1,
    'postel_code': 11011,
  },
  [
    'Milk',
    'Bread',
    'Spagetti',
    'Pasta',
    'Eggs',
  ],
  [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
  [
    [0, 1],
    [2, 3],
    [0, 1],
    [2, 3],
    [0, 1],
    [2, 3],
    [0, 1],
    [2, 3]
  ],
  [
    [0.1, 1.3],
    [2.1, 3.3],
    [0.1, 1.3],
    [2.1, 3.3],
    [0.1, 1.3],
    [2.1, 3.3],
    [0.1, 1.3],
    [2.1, 3.3]
  ]
];
