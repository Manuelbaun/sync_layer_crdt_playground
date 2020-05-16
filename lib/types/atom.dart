import 'package:meta/meta.dart';
import 'package:sync_layer/basic/hashing.dart';

import 'abstract/atom_base.dart';
import 'id.dart';

/// The [data] must be either an encodeable, which can be en/de coded by messagepack
/// or must be provided by the value en/decoder extension classes [ValueDecoder] [ValueEncoder]
///
/// if check for [==] equality, the value hashcode must be the same for the same copied value
/// Map/List etc do not have deep equality by default, hence two maps with the exact same values
/// do not have the same hashcode. To get the same hashcode loop over every entry and calculate the hashcode

/// This atom is used to transport the Data
class Atom<T> implements AtomBase<T> {
  Atom(this.id, {@required this.data})
      : assert(id != null),
        assert(data != null) {
    _hashCode = id.hashCode ^ nestedHashing(data);
  }

  @override
  final Id id;

  @override
  final T data;
  int _hashCode;

  /// TODO Test if it works as expected!
  @override
  int compareTo(AtomBase<T> other) => id.ts - other.id.ts;

  @override
  int compareToDESC(AtomBase<T> other) => -(id.ts - other.id.ts);

  @override
  String toString() => 'Atom(id: $id, data: $data)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is Atom && o.hashCode == hashCode;
  }

  @override
  int get hashCode => _hashCode;
}
