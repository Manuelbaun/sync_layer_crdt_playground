import 'package:sync_layer/abstract/syncable_object.dart';

abstract class ContainerAccessor<T> {
  ContainerAccessor(this.type);
  final String type;

  void onUpdate(String objectId, String fieldId, dynamic value);
  String generateID();
  SyncableObject objectLookup(String type, String id);
}
