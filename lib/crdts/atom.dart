import 'package:sync_layer/timestamp/index.dart';

abstract class AtomBase {
  final LogicalClock clock;
  final dynamic value;
  AtomBase(this.clock, this.value);
}

/// The [value] must be either an encodeable, which can be en/de coded by messagepack
/// or must be provided by the value en/decoder extension classes [ValueDecoder] [ValueEncoder]
///
/// if check for [==] equality, the value hashcode must be the same for the same copied value
/// Map/List etc do not have deep equality by default, hence two maps with the exact same values
/// do not have the same hashcode. To get the same hashcode loop over every entry and calculate the hashcode
class Atom<V> implements AtomBase, Comparable<Atom> {
  @override
  final Hlc clock;

  int get site => clock.site;
  int get logicaltime => clock.counter;

  @override
  final V value;

  Atom(this.clock, this.value);

  @override
  int compareTo(Atom other) {
    // TODO: FIxME
    return clock.counter - other.clock.counter;
  }

  int compareToDESC(Atom other) {
    // TODO: FIxME

    return other.clock.counter - clock.counter;
  }

  @override
  String toString() {
    return 'Atom(ts: ${clock.toRON()}, value: $value)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is Atom && o.hashCode == hashCode;
  }

  @override
  int get hashCode {
    var hash = 0;

    if (value is Map) {
      (value as Map).entries.forEach((e) => hash ^= e.key.hashCode ^ e.value.hashCode);
    } else if (value is List) {
      (value as List).forEach((e) => hash ^= e.hashCode);
    } else {
      hash = value.hashCode;
    }

    return clock.hashCode ^ hash;
  }
}
