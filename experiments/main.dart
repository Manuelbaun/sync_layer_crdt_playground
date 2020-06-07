import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/utils/measure.dart';

import 'dao.dart';

/// --------------------------------------------------------------
/// --------------------------------------------------------------
/// --------------------------------------------------------------
// create protocol class
final rand = Random(0);
final nodeID = rand.nextInt(999999);
final nodeIDRemote = rand.nextInt(999999);
var PATH = Directory.current.path + '\\';

List<IOSink> getFiles(String folder, int items) {
  final newPath = PATH + '$folder\\';
  final dir = Directory(newPath)..createSync(recursive: true);
  final path = dir.path + '\\';
  final file = File(path + '$items.csv').openWrite(mode: FileMode.append);
  final file2 = File(path + '${items}_remote.csv').openWrite(mode: FileMode.append);
  final file3 = File(path + '${items}_size.csv').openWrite(mode: FileMode.append);
  return [file, file2, file3];
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

void main(List<String> arguments) async {
  if (!PATH.contains('experiments')) PATH += 'experiments\\';
  var bools = <bool>[];
  var res = false;

  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);

    await exp(
      testName: 'map_e1',
      items: items,
      local: local,
      remote: remote,
      type: 'Map',
      func: (local) {
        final map = local.map.create();

        map.transact((ref) {
          for (var j = 0; j < items; j++) {
            ref[j] = itemsList[j];
          }
        });
        return map;
      },
    );

    bools.add(compare(local, remote));
  }

  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);

    await exp(
      testName: 'ct_e1',
      items: items,
      local: local,
      remote: remote,
      type: 'CT',
      func: (local) {
        final ct = local.array.create();

        ct.transact((ref) {
          for (var i = 0; i < items; i++) {
            ref.push(itemsList[i]);
          }
        });

        return ct;
      },
    );

    bools.add(compare(local, remote));
  }

  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);
    await exp(
      testName: 'ct_e2',
      items: items,
      local: local,
      remote: remote,
      type: 'CT',
      func: (local) {
        final ct = local.array.create();

        ct.transact((ref) {
          for (var i = 0; i < items; i++) {
            ref.insert(0, itemsList[i]);
          }
        });

        return ct;
      },
    );

    bools.add(compare(local, remote));
  }

  for (var items = 1; items <= itemsList.length; items++) {
    final local = SyncDao(nodeID);
    final remote = SyncDao(nodeIDRemote);
    await exp(
      testName: 'ct_e3',
      items: items,
      local: local,
      remote: remote,
      type: 'CT',
      func: (local) {
        final ct = local.array.create();

        ct.transact((ref) {
          for (var i = 0; i < items; i++) {
            var pos = items > 1 ? rand.nextInt(items - 1) : 0;
            ref.insert(pos, itemsList[i]);
          }
        });

        return ct;
      },
    );

    bools.add(compare(local, remote));
  }

  res = bools.every((e) => e == true);
  print(res);

  ct_e4_insert_vs_push();
}

void ct_e4_insert_vs_push() {
  final newPath = PATH + 'ct_e4\\';
  final dir = Directory(newPath)..createSync(recursive: true);
  final path = dir.path + '\\';

  // final remote = SyncDao(nodeIDRemote);

  final file = File(path + 'push_l_${DateTime.now().millisecondsSinceEpoch}.csv').openWrite(mode: FileMode.append);

  final file2 = File(path + 'rand_l_${DateTime.now().millisecondsSinceEpoch}.csv').openWrite(mode: FileMode.append);

  final l = SyncDao(nodeID);
  final l2 = SyncDao(nodeID);
  final r = SyncDao(nodeID);
  final r2 = SyncDao(nodeID);
  
  final ct_push = l.array.create('push_op');
  final ct_insert_random = l2.array.create('random_insert');

  final map_push = <int, String>{};
  final map_rand = <int, String>{};

  for (var i = 0; i < 10000; i++) {
    final us1 = measureExecution('ct push', () {
      ct_push.push('a');
    }, skipLog: true);

    final us2 = measureExecution('ct random insert', () {
      var pos = i > 1 ? rand.nextInt(i - 1) : 0;
      ct_insert_random.insert(pos, 'a');
    }, skipLog: true);

    map_push[i] = '$us1;';
    map_rand[i] = '$us2;';
  }

  final ll = {};
  var i = 0;
  for (var a in l.syn.atomCache.allAtoms) {
    final us1 = measureExecution('ct apply remote pushed atom', () {
      r.syn.applyRemoteAtoms([a]);
    }, skipLog: true);
    map_push[i++] += '$us1;\n';
  }

  i = 0;
  for (var a in l2.syn.atomCache.allAtoms) {
    final us1 = measureExecution('ct apply remote pushed atom', () {
      r2.syn.applyRemoteAtoms([a]);
    }, skipLog: true);
    map_rand[i++] += '$us1;\n';
  }

  map_push.forEach((i, v) {
    file.write(v);
  });

  map_rand.forEach((i, v) {
    file2.write(v);
  });

  file.close();
  file2.close();
}

void exp({
  int items,
  String type,
  String testName,
  SyncDao local,
  SyncDao remote,
  SyncableBase Function(SyncDao local) func,
}) async {
  final completers = <String, Completer>{};
  final us_map = <String, Map<String, dynamic>>{};

  local.syn.atomStream.listen((a) {
    final b = msgpackEncode(a);
    final payload = msgpackEncode(a.map((a) => a.data));
    String id;

    var us = measureExecution('$type remote $items:', () {
      final atoms = msgpackDecode(b);
      final aa = List<AtomBase>.from(atoms);
      id = aa[0].objectId;
      remote.syn.applyRemoteAtoms(aa);
    }, skipLog: true);

    us_map[id] ??= {};
    us_map[id]['remote'] = us;
    us_map[id]['size'] = b.length;
    us_map[id]['payload'] = payload.length;
    completers[id].complete();
  });

  for (var i = 0; i < 10; i++) {
    SyncableBase item;

    var us = measureExecution('$type $items:', () {
      item = func(local);
    }, skipLog: true);

    us_map[item.id] ??= {};
    us_map[item.id]['local'] = us;

    completers[item.id] = Completer();
  }

  await Future.wait(completers.values.map((c) => c.future));
  final files = getFiles(testName, items);

  us_map.values.forEach((e) {
    files[0].write('${e['local']};');
    files[1].write('${e['remote']};');
    double ratio = (e['payload'] / e['size']);
    files[2].write('${ratio.toStringAsFixed(3)};');
  });

  files.forEach((f) {
    f.write('\n');
    f.close();
  });
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
