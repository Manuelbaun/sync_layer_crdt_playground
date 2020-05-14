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
}
