import 'package:sync_layer/basic/hashing.dart';

import 'abstract/atom_base.dart';
import 'id.dart';

class Atom<T> implements AtomBase<T> {
  Atom(this.id, this.type, this.objectId, this.data);

  /// depending on the atom type, the id the hashcode of the atom or the clock
  // final IdBase id;
  @override
  final Id id;

  @override
  final int type;

  @override
  final String objectId;

  @override
  final T data;

  @override
  int compareTo(AtomBase other) => id.compareTo(other.id);

  @override
  int compareToDESC(AtomBase other) => -id.compareTo(other.id);

  @override
  String toString() => 'Atom($id, type: $type, objectId: $objectId, data: $data)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is Atom && o.hashCode == hashCode;
  }

  @override
  // should be enough!, since id, should be as unique as possible!
  // otherwise implement use objectType, etc
  int get hashCode => id.hashCode ^ objectId.hashCode ^ type ^ nestedHashing(data);
}
