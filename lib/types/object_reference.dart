import 'dart:convert';

/// Contains only the type and id of the object, to search if needed
/// this is used to transmit, instead of the syncable objects
class SyncableObjectRef {
  SyncableObjectRef(this.type, this.id);

  final int type;
  final String id;

  @override
  String toString() => 'ObjectReference(type: $type, id: $id)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is SyncableObjectRef && o.type == type && o.id == id;
  }

  @override
  int get hashCode => type.hashCode ^ id.hashCode;

  SyncableObjectRef copyWith({int type, String id}) {
    return SyncableObjectRef(type ?? this.type, id ?? this.id);
  }

  Map<String, dynamic> toMap() {
    return {'type': type, 'id': id};
  }

  static SyncableObjectRef fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return SyncableObjectRef(map['type'], map['id']);
  }

  String toJson() => json.encode(toMap());

  static SyncableObjectRef fromJson(String source) => fromMap(json.decode(source));
}
