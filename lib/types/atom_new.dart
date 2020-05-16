import 'package:meta/meta.dart';
import 'package:sync_layer/basic/hashing.dart';
import 'package:sync_layer/crdts/id/index.dart';

/// The [data] must be either an encodeable, which can be en/de coded by messagepack
/// or must be provided by the value en/decoder extension classes [ValueDecoder] [ValueEncoder]
///
/// if check for [==] equality, the value hashcode must be the same for the same copied value
/// Map/List etc do not have deep equality by default, hence two maps with the exact same values
/// do not have the same hashcode. To get the same hashcode loop over every entry and calculate the hashcode

abstract class AtomBase<T> {
  /// depending on the atom type, the id the hashcode of the atom or the clock
  final Id id;
  final T data;
  AtomBase(this.id, this.data);
}

/// This atom is used to transport the Data
class Atom<T> implements AtomBase<T>, Comparable<Atom<T>> {
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

  @override
  int compareTo(Atom<T> other) => id.ts.compareTo(other.id.ts);
  int compareToDESC(Atom<T> other) => id.ts.compareTo(other.id.ts) * -1;

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
