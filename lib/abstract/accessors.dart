import 'package:sync_layer/abstract/syncable_object.dart';
import 'package:sync_layer/types/index.dart';

/// [V] is not for a syncable object,
/// it should describe the type of the value, which is then updated
abstract class Accessor {
  Accessor(this.type);
  final String type;

  void onUpdate<V>(List<V> value);
  String generateID();
  SyncableObject objectLookup(ObjectReference ref);
}
