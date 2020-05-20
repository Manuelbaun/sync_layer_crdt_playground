import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/object_reference.dart';

import 'abstract/acess_proxy.dart';
import 'abstract/sync_layer.dart';

class SynclayerAccessor implements AccessProxy {
  SynclayerAccessor(this.synclayer, int type)
      : _type = type,
        assert(synclayer != null),
        assert(type != null);

  final SyncLayer synclayer;

  final int _type;
  @override
  int get type => _type;

  @override
  int get site => synclayer.site;

  @override
  AtomBase update(String objectId, dynamic data, bool isLocal) {
    final atom = synclayer.createAtom(objectId, type, data);

    /// with local update
    synclayer.applyAtoms([atom], isLocalUpdate: isLocal);
    return atom;
  }

  @override
  String generateID() => synclayer.generateID();

  @override
  SyncableBase objectLookup(ObjectReference ref, [bool shouldCreateIfNull = true]) {
    final container = synclayer.getObjectContainer(typeNumber: ref.type);

    if (container != null) {
      var obj = container.read(ref.id);

      if (shouldCreateIfNull && obj == null) obj = container.create(ref.id);

      return obj;
    }
    throw AssertionError('Container  could not be found');
  }
}
