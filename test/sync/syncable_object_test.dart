import 'dart:async';

import 'package:sync_layer/abstract/index.dart';
import 'package:sync_layer/types/index.dart';
import 'package:sync_layer/impl/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'package:sync_layer/basic/hashing.dart';
import 'package:test/test.dart';

// TODO: Test accessing syncable object
// todo: subtye syncable object!

class TestAccessor implements Accessor {
  TestAccessor(this.type, this.site, this.update) {
    baseClock = Hlc(DateTime(2020).millisecondsSinceEpoch, 0, site);
  }

  Hlc baseClock;
  void Function(Atom) update;
  final int site;
  @override
  String type;

  @override
  void onUpdate<V>(List<V> values) {
    final atoms = values.map((v) {
      // creates new baseClock
      baseClock = Hlc.send(baseClock);
      // send atom with that baseClock
      return Atom(baseClock, v);
    });

    atoms.forEach(update);
    // so.applyAtom(a);
  }

  @override
  String generateID() {
    return '__hello_world__';
  }

  @override
  SyncableObject objectLookup(ObjectReference ref) {
    return null;
  }
}

void main() {
  group('Basic: ', () {
    final type = 'todo';
    SyncableObject obj1;
    var atoms1 = <Atom>[];
    final access1 = TestAccessor(type, 22222, (Atom a) => atoms1.add(a));

    setUp(() {
      // create test object
      obj1 = SyncableObjectImpl(null, access1);
      atoms1 = [];
    });

    test('Setup Syncable object', () {
      expect(obj1.id, '__hello_world__');
      expect(obj1.tombstone, isFalse);
      expect(obj1.type, type);
    });

    test('Set simple fields ', () {
      obj1['1'] = 'Hans';
      obj1['2'] = 123;
      obj1['3'] = {2, 3};
      obj1['4'] = {2: 3};
      obj1['5'] = {'2': 'some string'};
      obj1['6'] = {'2': 1234};
      // nested map
      obj1['7'] = {
        '2': {
          '3': {5: 'hello'}
        }
      };

      expect(obj1['1'] == null, isTrue);
      expect(obj1['2'] == null, isTrue);
      expect(obj1['3'] == null, isTrue);
      expect(obj1['4'] == null, isTrue);
      expect(obj1['5'] == null, isTrue);
      expect(obj1['6'] == null, isTrue);
      expect(obj1['7'] == null, isTrue);

      atoms1.forEach(obj1.applyAtom);

      expect(obj1['1'] == 'Hans', isTrue);
      expect(obj1['2'] == 123, isTrue);
      expect(nestedHashing(obj1['3']) == nestedHashing({2, 3}), isTrue);
      expect(nestedHashing(obj1['4']) == nestedHashing({2: 3}), isTrue);
      expect(nestedHashing(obj1['5']) == nestedHashing({'2': 'some string'}), isTrue);
      expect(nestedHashing(obj1['6']) == nestedHashing({'2': 1234}), isTrue);

      // nested
      expect(
          nestedHashing(obj1['7']) ==
              nestedHashing({
                '2': {
                  '3': {5: 'hello'}
                }
              }),
          isTrue);
    });

    test('CRDT Properties Last Writer Wins', () {
      obj1['early'] = 'now';
      obj1['early'] = 'now2';

      // updates first, the second atom
      expect(obj1.applyAtom(atoms1[1]), 2);
      expect(obj1.history.length, 1);
      // then the first Atom
      expect(obj1.applyAtom(atoms1[0]), 0);
      expect(obj1.history.length, 2);

      // apply the exact same atom twice
      expect(obj1.applyAtom(atoms1[1]), 1);
      expect(obj1.history.length, 2);

      // the same old atom, still should give one! =>
      expect(obj1.applyAtom(atoms1[0]), 0);
      expect(obj1.history.length, 2);

      // apply null as atom
      try {
        obj1.applyAtom(null);
      } catch (e) {
        expect(e is NoSuchMethodError, isTrue);
      }

      expect(obj1['early'], 'now2');
      expect(obj1['early'] == 'now', isFalse);
    });

    test('CRDT Properties Merge two Objects on different sides', () {
      obj1['early'] = 'now';
      obj1['early'] = 'now2';

      // updates first, the second atom
      expect(obj1.applyAtom(atoms1[1]), 2);
      expect(obj1.history.length, 1);
      // then the first Atom
      expect(obj1.applyAtom(atoms1[0]), 0);
      expect(obj1.history.length, 2);

      // apply the exact same atom twice
      expect(obj1.applyAtom(atoms1[1]), 1);
      expect(obj1.history.length, 2);

      // the same old atom, still should give one! =>
      expect(obj1.applyAtom(atoms1[0]), 0);
      expect(obj1.history.length, 2);

      // apply null as atom
      try {
        obj1.applyAtom(null);
      } catch (e) {
        expect(e is NoSuchMethodError, isTrue);
      }

      expect(obj1['early'], 'now2');
      expect(obj1['early'] == 'now', isFalse);
    });
  });

  group('Merging: ', () {
    final type = 'todo';
    SyncableObject obj1;
    SyncableObject obj2;

    var atoms1 = <Atom>[];
    var atoms2 = <Atom>[];

    final access1 = TestAccessor(type, 11111, (Atom a) => atoms1.add(a));
    final access2 = TestAccessor(type, 22222, (Atom a) => atoms2.add(a));

    setUp(() {
      // create test object
      obj1 = SyncableObjectImpl(null, access1);
      obj2 = SyncableObjectImpl(null, access2);
      atoms1 = [];
      atoms2 = [];
    });

    test('Compare same Id', () {
      expect(obj1.id == obj2.id, isTrue);
    });

    test('apply same fields', () {
      obj1['1'] = 1;
      obj2['1'] = 1;

      atoms1.forEach(obj1.applyAtom);
      atoms2.forEach(obj2.applyAtom);

      expect(obj1.getFieldClock('1') == obj2.getFieldClock('1'), isFalse);
      expect(obj1.getFieldClock('1').site, 11111);
      expect(obj2.getFieldClock('1').site, 22222);

      // depending on the time, the clock is created, it could be the same ms or just one after another
      expect(atoms1[0].clock == atoms2[0].clock || atoms1[0].clock < atoms2[0].clock, isTrue);
    });

    test('apply same fields and merge', () {
      obj1['1'] = 1;
      obj2['1'] = 'Test';

      atoms1.forEach(obj1.applyAtom);
      atoms2.forEach(obj2.applyAtom);

      expect(obj1.getFieldClock('1') == obj2.getFieldClock('1'), isFalse);
      expect(obj1.getFieldClock('1').site, 11111);
      expect(obj2.getFieldClock('1').site, 22222);

      /// --------------------------------
      /// --------------------------------
      // merge now both atoms
      atoms2.forEach(obj1.applyAtom);
      atoms1.forEach(obj2.applyAtom);

      expect(obj1.getFieldClock('1') == obj2.getFieldClock('1'), isTrue);
      expect(obj1.getFieldClock('1').site, 22222);
      expect(obj2.getFieldClock('1').site, 22222);

      expect(obj1['1'], 'Test');
      expect(obj2['1'], 'Test');
    });

    test('apply same fields and merge with time delay', () {
      Timer(Duration(milliseconds: 1), () {
        obj2['1'] = 'Test';
      });

      Timer(Duration(milliseconds: 50), () {
        obj1['1'] = 1;
        atoms1.forEach(obj1.applyAtom);
        atoms2.forEach(obj2.applyAtom);

        expect(obj1.getFieldClock('1') == obj2.getFieldClock('1'), isFalse);
        expect(obj1.getFieldClock('1').site, 11111);
        expect(obj2.getFieldClock('1').site, 22222);

        /// --------------------------------
        /// --------------------------------
        // merge now both atoms
        atoms2.forEach(obj1.applyAtom);
        atoms1.forEach(obj2.applyAtom);

        expect(obj1.getFieldClock('1') == obj2.getFieldClock('1'), isTrue);
        expect(obj1.getFieldClock('1').site, 11111);
        expect(obj2.getFieldClock('1').site, 11111);

        expect(obj1['1'], 1);
        expect(obj2['1'], 1);
      });
    });

    test('apply same fields and increase counter', () {
      obj1['1'] = 'Peter';
      obj1['1'] = 'Pan';
      obj1['1'] = 'Hans';

      atoms1.forEach(obj1.applyAtom);

      final clock = obj1.getFieldClock('1');
      expect(atoms1.length, 3);

      // if counter is 0 => 'Hans' was just set, when the milliseconds went up by one
      // if counter is 1 => 'Hans' was just set, when 'Pan' was on new milliseconds
      // if counter is 2 => 'Hans' was set, in the same milliseconds with 'Peter' and 'Pan'
      // 2 is most likly
      // verything else is a fail!
      expect(clock.counter >= 0 && clock.counter <= 2, isTrue);
    });
  });

  group('Types', () {
    final type = 'todo';
    SyncableObject obj1;
    SyncableObject obj2;

    var atoms1 = <Atom>[];
    var atoms2 = <Atom>[];

    final access1 = TestAccessor(type, 11111, (Atom a) => atoms1.add(a));
    final access2 = TestAccessor(type, 22222, (Atom a) => atoms2.add(a));

    setUp(() {
      // create test object
      obj1 = SyncableObjectImpl(null, access1);
      obj2 = SyncableObjectImpl(null, access2);
      atoms1 = [];
      atoms2 = [];
    });
  });
}
