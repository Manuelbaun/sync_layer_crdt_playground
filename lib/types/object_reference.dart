import 'dart:convert';

class ObjectReference {
  ObjectReference(this.type, this.id);

  final int type;
  final String id;

  @override
  String toString() => 'ObjectReference(type: $type, id: $id)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ObjectReference && o.type == type && o.id == id;
  }

  @override
  int get hashCode => type.hashCode ^ id.hashCode;

  ObjectReference copyWith({int type, String id}) {
    return ObjectReference(type ?? this.type, id ?? this.id);
  }

  Map<String, dynamic> toMap() {
    return {'type': type, 'id': id};
  }

  static ObjectReference fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return ObjectReference(map['type'], map['id']);
  }

  String toJson() => json.encode(toMap());

  static ObjectReference fromJson(String source) => fromMap(json.decode(source));
}
