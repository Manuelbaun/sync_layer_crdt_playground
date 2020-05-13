import 'package:sync_layer/logical_clocks/index.dart';
import 'package:sync_layer/basic/hashing.dart';

import 'atom_base.dart';

/// The [data] must be either an encodeable, which can be en/de coded by messagepack
/// or must be provided by the value en/decoder extension classes [ValueDecoder] [ValueEncoder]
///
/// if check for [==] equality, the value hashcode must be the same for the same copied value
/// Map/List etc do not have deep equality by default, hence two maps with the exact same values
/// do not have the same hashcode. To get the same hashcode loop over every entry and calculate the hashcode

class Atom<T> implements AtomBase, Comparable<Atom<T>> {
  @override
  final LogicalClock clock;

  int get site => clock.site;
  int get counter => clock.counter;

  @override
  final T data;

  Atom(this.clock, this.data);

  @override
  int compareTo(Atom<T> other) {
    return clock.compareTo(other.clock);
  }

  @override
  String toString() {
    return 'Atom(ts: ${clock.toStringHuman()}, value: $data)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is Atom && o.hashCode == hashCode;
  }

  @override
  int get hashCode {
    return clock.hashCode ^ nestedHashing(data);
  }
}
