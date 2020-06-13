import 'package:sync_layer/index.dart';
import 'package:sync_layer/logger/index.dart';
import 'package:sync_layer/sync/abstract/index.dart';
import 'package:sync_layer/sync/index.dart';
import 'package:sync_layer/sync/syncable_causal_tree.dart';
import 'package:sync_layer/sync/syncable_object_impl.dart';

class SyncArray extends SyncableCausalTree<dynamic, SyncArray> {
  SyncArray(AccessProxy accessor, {String id}) : super(accessor, id);
}

class SyncDao {
  static SyncDao _instance;
  static SyncDao get instance => _instance;
  final int nodeID;

  static SyncDao getInstance(int nodeId) {
    _instance ??= SyncDao(nodeId);
    return _instance;
  }

  SyncDao(this.nodeID) {
    if (_instance == null) {
      _syn = SynchronizerImple(nodeID);
      _protocol = SyncLayerProtocol(_syn);

      // create first container by type
      _array = syn.registerObjectType<SyncArray>('syncarray', (c, id) => SyncArray(c, id: id));
      _map = syn.registerObjectType<SyncableMap>('map', (c, id) => SyncableMap(c, id));
    } else {
      throw AssertionError('cant create this class twice?');
    }
  }

  SyncLayerProtocol _protocol;
  SyncLayerProtocol get protocol => _protocol;

  SynchronizerImple _syn;
  SynchronizerImple get syn => _syn;

  SyncableObjectContainer<SyncArray> get array => _array;
  SyncableObjectContainer<SyncArray> _array;

  SyncableObjectContainer<SyncableMap> get map => _map;
  SyncableObjectContainer<SyncableMap> _map;
}
