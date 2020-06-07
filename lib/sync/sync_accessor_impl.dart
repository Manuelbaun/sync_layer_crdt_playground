import 'package:sync_layer/sync/abstract/syncable_base.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/object_reference.dart';

import 'abstract/acess_proxy.dart';
import 'abstract/synchronizer.dart';

/// [SynclayerAccessor] is to be used within a syncablebase object
class SynclayerAccessor implements AccessProxy {
  SynclayerAccessor(this.synclayer, int type)
      : _type = type,
        assert(synclayer != null),
        assert(type != null);

  final Synchronizer synclayer;

  final int _type;
  @override
  int get type => _type;

  @override
  int get site => synclayer.site;

  /// should only be called within a synable base object
  @override
  AtomBase mutate(String objectId, dynamic data) {
    final atom = synclayer.createAtom(type, objectId, data);
    synclayer.applyLocalAtoms([atom]);
    return atom;
  }

  @override
  String generateID() => synclayer.generateNewObjectIds();

  @override
  SyncableBase refLookup(SyncableObjectRef ref, [bool shouldCreateIfNull = true]) {
    final container = synclayer.getObjectContainer(typeNumber: ref.type);

    if (container != null) {
      var obj = container.read(ref.id);

      if (shouldCreateIfNull && obj == null) obj = container.create(ref.id);

      return obj;
    }
    throw AssertionError('Container  could not be found');
  }
}
