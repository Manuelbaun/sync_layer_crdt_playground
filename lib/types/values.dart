/// Importent Key and value cant be some custom class type!!!
/// unless encoding and decoding is implemented
/// in the  encoding_extent classes
/// 

class Value {
  /// In Context  of a Db, it's the **[Table]** id
  final int typeId;

  /// in Context of  a Db, its the **[Row]** id could be cuid id or any other
  final String id;

  /// In context ob a Db it is the **[column]**
  final dynamic key;

  /// In context of a Db its the **[value]** of the column
  final dynamic value;

  Value(this.typeId, this.id, this.key, this.value);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Value && o.typeId == typeId && o.id == id && o.key == key && o.value == value;
  }

  @override
  int get hashCode {
    return typeId.hashCode ^ id.hashCode ^ key.hashCode ^ value.hashCode;
  }

  @override
  String toString() {
    return 'Value(id: $id, type: $typeId, field: $key, value: $value)';
  }
}
