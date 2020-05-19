import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/atom.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';
import 'package:sync_layer/types/id_atom.dart';
import 'package:sync_layer/types/object_reference.dart';

class FakeAccessorHLC implements AcessProxy {
  FakeAccessorHLC(this.type, this.site, this.onUpdate) {
    baseClock = HybridLogicalClock(DateTime(2020).millisecondsSinceEpoch, 0);
  }

  LogicalClockBase baseClock;
  void Function(AtomBase) onUpdate;

  // setter not defined?
  @override
  final int site;

  // setter not defined?
  @override
  final int type;

  AtomId _getNextAtomId() {
    baseClock = HybridLogicalClock.send(baseClock);
    return AtomId(baseClock, site);
  }

  @override
  AtomBase update(String objId, dynamic data) {
    final tsId = _getNextAtomId();
    final a = Atom(tsId, type, objId, data);
    if (update != null) onUpdate(a);
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
