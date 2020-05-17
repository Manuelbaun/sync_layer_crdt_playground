import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/object_reference.dart';

import 'abstract/accessors.dart';
import 'abstract/sync_layer.dart';
import 'abstract/syncable_object.dart';

class SynclayerAccessor implements Accessor {
  SynclayerAccessor(this.synclayer, this.type);

  final SyncLayer synclayer;

  @override
  final int type;

  @override
  AtomBase onUpdate(String objectId, dynamic data) {
    final atom = synclayer.createAtom(objectId, type, data);
    synclayer.applyAtoms([atom]);
    return atom;
  }

  @override
  String generateID() {
    return synclayer.generateID();
  }

  @override
  SyncableObject objectLookup(ObjectReference ref, [bool shouldCreateIfNull = true]) {
    final container = synclayer.getObjectContainer(typeNumber: ref.type);

    // TODO: check if container Exists
    var obj = container.read(ref.id);

    if (shouldCreateIfNull && obj == null) {
      obj = container.create(ref.id);
    }
    return obj;
  }
}
