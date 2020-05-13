import 'package:sync_layer/abstract/syncable_object.dart';

typedef OnFieldUpdate = void Function(String objectId, String fieldId, dynamic value);
typedef GenerateID = String Function();
typedef ObjectLookup = SyncableObject Function(String type, String id);

class ContainerAccessor {
  ContainerAccessor({this.onUpdate, this.generateID, this.objectLookup, this.type});
  final String type;
  final OnFieldUpdate onUpdate;
  final GenerateID generateID;
  final ObjectLookup objectLookup;
}
