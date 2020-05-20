import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/atom.dart';
import 'package:sync_layer/types/hybrid_logical_clock.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/object_reference.dart';

class FakeAccessProxyHLC implements AccessProxy {
  FakeAccessProxyHLC(this.type, this.site, this.onUpdate) {
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

  Id _getNextAtomId() {
    baseClock = HybridLogicalClock.send(baseClock);
    return Id(baseClock, site);
  }

  @override
  AtomBase update(String objId, dynamic data) {
    final tsId = _getNextAtomId();
    final a = Atom(tsId, type, objId, data);
    if (update != null) onUpdate(a);
    return a;
  }

  @override
  String generateID() => '__hello_world__';

  var db = <String, SyncableBase>{};

  @override
  SyncableBase objectLookup(SyncableObjectRef ref) {
    return db[ref.id];
  }
}
