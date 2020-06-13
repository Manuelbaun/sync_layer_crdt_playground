import 'dart:async';

import 'package:sync_layer/basic/hashing.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync/abstract/syncable_object.dart';
import 'package:sync_layer/sync/syncable_object_impl.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';

import 'package:test/test.dart';

import '../utils/fake_accessor.dart';

// TODO: Test accessing syncable object
// todo: subtye syncable object!

class Test<K> {
  Test() {
    print(K.hashCode);
    print(K.runtimeType);
    print(K); // hashcode 913556373 DateTime
    print(int); // hashCode 292397006
    print(String); // hashcode string 247315299
  }
}

void main() {
  // Test<String>();
  // Test<int>();
  // Test<DateTime>();
  group('Basic: ', () {
    final type = 'todo'.hashCode;
    SyncableObject obj1;
    SyncableObject obj2;

    var atoms1 = <AtomBase>[];
    final access1 = FakeAccessProxyHLC(type, 22222, (AtomBase a) {
      logger.info(a.toString());
      atoms1.add(a);
    });

    setUp(() {
      // create test object
      obj1 = SyncableMap(access1, null);
      obj2 = SyncableMap(access1, null);

      // obj1.onChange.listen((n) => print(obj1));

      // obj1[null] = 'hallo';
      atoms1.clear();
    });

    test('Setup Syncable object', () {
      expect(obj1.id, '__hello_world__');
      expect(obj1.tombstone, isFalse);
      expect(obj1.type, type);
    });

    test('Set simple fields ', () {
      obj1[1] = 'Hans';
      obj1[2] = 123;
      obj1[3] = {2, 3};
      obj1[4] = {2: 3};
      obj1[5] = {2: 'some string'};
      obj1[6] = {2: 1234};
      // nested map
      obj1[7] = {
        2: {
          3: {5: 'hello'}
        }
      };

      expect(obj1[1] == 'Hans', isTrue);
      expect(obj1[2] == 123, isTrue);
      expect(nestedHashing(obj1[3]) == nestedHashing({2, 3}), isTrue);
      expect(nestedHashing(obj1[4]) == nestedHashing({2: 3}), isTrue);
      expect(nestedHashing(obj1[5]) == nestedHashing({2: 'some string'}), isTrue);
      expect(nestedHashing(obj1[6]) == nestedHashing({2: 1234}), isTrue);

      // nested
      expect(
          nestedHashing(obj1[7]) ==
              nestedHashing({
                2: {
                  3: {5: 'hello'}
                }
              }),
          isTrue);

      print(obj1.toString());
    });

    test('CRDT Properties Last Writer Wins', () {
      obj1[20] = 'now';
      expect(obj1.history.length, 1);

      obj1[20] = 'now2';

      // apply the exact same atom twice
      expect(obj1.applyRemoteAtom(atoms1[0]), -1);
      expect(obj1.applyRemoteAtom(atoms1[1]), -1);
      expect(obj1.history.length, 2);

      // apply null as atom
      expect(obj1.applyRemoteAtom(null), -2);

      expect(obj1[20], 'now2');
      expect(obj1[20] == 'now', isFalse);
    });

    test('CRDT Properties Merge two Objects on different sides', () {
      obj1[30] = 'now';
      obj1[30] = 'now2';

      // updates first, the second atom
      expect(obj1.applyRemoteAtom(atoms1[0]), -1);
      expect(obj1.history.length, 2);
      // then the first Atom
      expect(obj1.applyRemoteAtom(atoms1[1]), -1);
      expect(obj1.history.length, 2);

      // updates first, the second atom
      expect(obj2.applyRemoteAtom(atoms1[0]), 2);
      expect(obj2.history.length, 1);
      expect(obj2.applyRemoteAtom(atoms1[1]), 2);
      expect(obj2.history.length, 2);

      // apply null as atom

      expect(obj1.applyRemoteAtom(null), -2);

      expect(obj1[30], 'now2');
      expect(obj1[30] == 'now', isFalse);
    });
  });

  group('Merging: ', () {
    final type = 'todo'.hashCode;
    SyncableObject obj1;
    SyncableObject obj2;

    var atoms1 = <AtomBase>[];
    var atoms2 = <AtomBase>[];

    final access1 = FakeAccessProxyHLC(type, 11111, (AtomBase a) => atoms1.add(a));
    final access2 = FakeAccessProxyHLC(type, 22222, (AtomBase a) => atoms2.add(a));

    setUp(() {
      // create test object
      obj1 = SyncableMap(
        access1,
        'obj',
      );
      obj2 = SyncableMap(
        access2,
        'obj',
      );
      atoms1 = [];
      atoms2 = [];
    });

    test('Compare same Id', () {
      expect(obj1.id == obj2.id, isTrue);
    });

    test('apply same fields', () {
      obj1[1] = 1;
      obj2[1] = 1;

      atoms1.forEach(obj1.applyRemoteAtom);
      atoms2.forEach(obj2.applyRemoteAtom);

      final id1 = obj1.getOriginIdOfKey(1);
      final id2 = obj2.getOriginIdOfKey(1);

      expect(id1 == id2, isFalse);
      expect(id1.site, 11111);
      expect(id2.site, 22222);

      // depending on the time, the clock is created, it could be the same ms or just one after another
      final a = atoms1[0];
      final b = atoms2[0];
      expect(a.id == b.id || a.id < b.id, isTrue);
      print('ok');
    });

    test('apply same fields and merge', () {
      obj1[1] = 1;
      obj2[1] = 'Test';

      atoms1.forEach(obj1.applyRemoteAtom);
      atoms2.forEach(obj2.applyRemoteAtom);

      final id1 = obj1.getOriginIdOfKey(1);
      final id2 = obj2.getOriginIdOfKey(1);

      expect(id1 == id2, isFalse);
      expect(id1.site, 11111);
      expect(id2.site, 22222);

      /// --------------------------------
      /// --------------------------------
      // merge now both atoms
      atoms2.forEach(obj1.applyRemoteAtom);
      atoms1.forEach(obj2.applyRemoteAtom);

      final id11 = obj1.getOriginIdOfKey(1);
      final id22 = obj2.getOriginIdOfKey(1);

      expect(id11 == id22, isTrue);
      expect(id11.site, 22222);
      expect(id22.site, 22222);

      expect(obj1[1], 'Test');
      expect(obj2[1], 'Test');
    });

    test('apply same fields and merge with time delay', () {
      Timer(Duration(milliseconds: 1), () {
        obj2[1] = 'Test';
      });

      Timer(Duration(milliseconds: 100), () {
        obj1[1] = 1;
        atoms1.forEach(obj1.applyRemoteAtom);
        atoms2.forEach(obj2.applyRemoteAtom);

        final id1 = obj1.getOriginIdOfKey(1);
        final id2 = obj2.getOriginIdOfKey(1);

        expect(id1 == id2, isFalse);
        expect(id1.site, 11111);
        expect(id2.site, 22222);

        /// --------------------------------
        /// --------------------------------
        // merge now both atoms
        atoms2.forEach(obj1.applyRemoteAtom);
        atoms1.forEach(obj2.applyRemoteAtom);

        final id11 = obj1.getOriginIdOfKey(1);
        final id22 = obj2.getOriginIdOfKey(1);

        expect(id11 == id22, isTrue);
        expect(id11.site, 11111);
        expect(id22.site, 11111);

        expect(obj1[1], 1);
        expect(obj2[1], 1);
      });
    });

    test('apply same fields and increase counter', () {
      obj1[1] = 'Peter';
      obj1[1] = 'Pan';
      obj1[1] = 'Hans';

      atoms1.forEach(obj1.applyRemoteAtom);

      final clock = obj1.getOriginIdOfKey(1);
      expect(atoms1.length, 3);

      // if counter is 0 => 'Hans' was just set, when the milliseconds went up by one
      // if counter is 1 => 'Hans' was just set, when 'Pan' was on new milliseconds
      // if counter is 2 => 'Hans' was set, in the same milliseconds with 'Peter' and 'Pan'
      // 2 is most likly
      // verything else is a fail!
      expect((clock.ts as HybridLogicalClock).counter >= 0 && (clock.ts as HybridLogicalClock).counter <= 2, isTrue);
    });
  });

  group('Types', () {
    final type = 'todo'.hashCode;
    SyncableObject obj1;
    SyncableObject obj2;

    var atoms1 = <AtomBase>[];
    var atoms2 = <AtomBase>[];

    final access1 = FakeAccessProxyHLC(type, 11111, (AtomBase a) => atoms1.add(a));
    final access2 = FakeAccessProxyHLC(type, 22222, (AtomBase a) => atoms2.add(a));

    setUp(() {
      // create test object
      obj1 = SyncableMap(access1, 'object_ID3');
      obj2 = SyncableMap(access2, 'object_ID4');
      atoms1 = [];
      atoms2 = [];
    });
  });
}
