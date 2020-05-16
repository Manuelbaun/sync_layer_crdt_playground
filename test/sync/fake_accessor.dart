import 'package:sync_layer/sync/abstract/accessors.dart';
import 'package:sync_layer/sync/abstract/syncable_object.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/atom.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';

import 'package:sync_layer/types/id.dart';

import 'package:sync_layer/types/object_reference.dart';

class FakeAccessor implements Accessor {
  FakeAccessor(this.type, this.site, this.update) {
    baseClock = HybridLogicalClock(DateTime(2020).millisecondsSinceEpoch, 0);
  }

  LogicalClockBase baseClock;
  void Function(AtomBase) update;
  final int site;
  @override
  int type;

  @override
  void onUpdate<V>(List<V> data) {
    final atoms = data.map((d) {
      // creates new baseClock
      baseClock = HybridLogicalClock.send(baseClock);
      // send atom with that baseClock
      return Atom(Id(baseClock, site), data: d);
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
