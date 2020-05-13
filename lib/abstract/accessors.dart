import 'package:sync_layer/abstract/syncable_object.dart';

abstract class Accessor<T> {
  Accessor(this.type);
  final String type;

  void onUpdate(List<T> value);
  String generateID();
  SyncableObject objectLookup(String type, String id);
}
