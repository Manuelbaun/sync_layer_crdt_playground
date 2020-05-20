import 'package:sync_layer/encoding_extent/index.dart';

import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/sync/index.dart';
import 'package:sync_layer/sync/syncable_causal_tree.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:test/test.dart';

import '../utils/fake_accessor.dart';

class FakeNetwork {
  final map = <String, SyncableBase>{};

  void register(SyncableBase obj) {
    if (!map.containsKey(obj.proxy.site)) {
      map['ID${obj.id} @ S${obj.proxy.site}'] = obj;
    }
  }

  void add(AtomBase a) {
    final atomBytes = msgpackEncode(a);
    final atom = msgpackDecode(atomBytes);
    for (var obj in map.entries) {
      if (a.id.site != obj.value.proxy.site && obj.value.type == a.type) {
        obj.value.applyRemoteAtom(atom);
      }
    }
  }
}

void main() {
  syncableCausalTree();
  nested();
}

void syncableCausalTree() {
  final network = FakeNetwork();
  final acc1 = FakeAccessProxyHLC('CausalTree'.hashCode, 0xa, network.add);
  final acc2 = FakeAccessProxyHLC('CausalTree'.hashCode, 0xb, network.add);

  final list1 = SyncableCausalTree(acc1, 'line1');
  final list2 = SyncableCausalTree(acc2, 'line1');

  network.register(list1);
  network.register(list2);

  list1.push('h');
  list1.push('e');
  list1.push('l');
  list1.push('o');

  list1.insert(3, 'l');

  test('is equal', () {
    expect(list1.values.join(''), 'hello');
    expect(list2.values.join(''), 'hello');
  });
}

void nested() {
  final network = FakeNetwork();
  final acc1 = FakeAccessProxyHLC(111, 0xa, network.add);
  final acc2 = FakeAccessProxyHLC(222, 0xa, network.add);

  final acc3 = FakeAccessProxyHLC(111, 0xb, network.add);
  final acc4 = FakeAccessProxyHLC(222, 0xb, network.add);

  final list1 = SyncableCausalTree(acc1, 'tree');
  final obj1 = SyncableObjectImpl(acc2, 'obj');
  final obj12 = SyncableObjectImpl(acc2, 'obj2');

  final list2 = SyncableCausalTree(acc3, 'tree');
  final obj2 = SyncableObjectImpl(acc4, 'obj');

  network.register(obj1);
  network.register(obj2);

  /// probably infinity loop
  network.register(list1);
  network.register(list2);

  /// add objects for look up!
  final db = {
    list1.id: list1,
    list2.id: list2,
    obj1.id: obj1,
    obj12.id: obj12,
    obj2.id: obj2,
  };

  acc1.db = db;
  acc2.db = db;
  acc3.db = db;
  acc4.db = db;

  // now nest objs
  obj1[0] = list1;
  list1.push('Hans');
  list1.push('Peter');
  list1.push(obj1);

  SyncableCausalTree h = obj2[0];

  var i = 0;
  final list1_list2 = list1.entriesUnfiltered.every((a) {
    final b = list2.entriesUnfiltered[i];
    final c = h.entriesUnfiltered[i];
    i++;
    // print('$a - $b - $c');
    return a == b && a == c && b == c;
  });

  test('is equal', () {
    expect(list1_list2, isTrue);
  });
}
