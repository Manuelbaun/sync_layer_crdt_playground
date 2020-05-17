import 'package:sync_layer/sync/abstract/accessors.dart';
import 'package:sync_layer/sync/abstract/syncable_object.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/atom.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';

import 'package:sync_layer/types/id_atom.dart';

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

  AtomId _getNextTimeId() {
    baseClock = HybridLogicalClock.send(baseClock);
    return AtomId(baseClock, site);
  }

  @override
  AtomBase onUpdate(String objId, dynamic data) {
    final tsId = _getNextTimeId();
    final a = Atom(tsId, type, objId, data);
    update(a);
    return a;
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
