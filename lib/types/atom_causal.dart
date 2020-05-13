import 'package:sync_layer/logical_clocks/index.dart';

import 'atom_base.dart';

/// Todo  must be also en/decodeable!!!
class CausalAtom<T> implements AtomBase, Comparable<CausalAtom> {
  @override
  LogicalTime clock;

  int get site => clock.site;
  int get counter => clock.counter;

  @override
  final T data;

  final LogicalTime cause;

  CausalAtom(this.clock, this.data, this.cause);

  /// Checks wheter Atom **lhs** is causal **`less`** then **rhs**.
  /// Less means it is **left** to the other atom in the array.
  ///
  /// `**Note**: you can use the < operator`
  ///
  /// Rules:
  /// 1. If Atoms are sequence of charactors, then it is sorted by the timestamp [ASC Order]
  /// 2. If two Atoms don't have the same cause, they are not either sequence nor related
  /// 3. If same cause (parent): Then the Atom with the highest timestamp is right next to the parent in the array.
  /// The highest timestamp means the youngest atom or the lastest edit.
  /// 4. if the times are equal, then it gets sorted by the site [DESC ORDER]
  static int compare(CausalAtom left, CausalAtom right) {
    // if cause is equal => siblings
    if (left.cause == right.cause) {
      if (left.clock > right.clock) {
        return -1;
      } else if (left.clock == right.clock) {
        // TODO: test if this comapre is correct!
        return right.site - left.site;
      }
    }

    return 0;
  }

  static bool isSibling(CausalAtom a, CausalAtom b) => a.cause == b.cause;

  /// This function only to be used in the context when two atoms are siblings to the same cause.
  /// then a loop should call this function to compare if the atom on the left side
  /// is still
  static bool leftIsLeft(CausalAtom left, CausalAtom right) {
    if (left.clock > right.clock) {
      return true;
    } else if (left.clock == right.clock) {
      return left.site > right.site;
    }
    return false;
  }

  @override
  int compareTo(CausalAtom other) {
    // TODO: FIxME

    return clock.counter - other.clock.counter;
  }

  String get siteId => 'S${site?.toRadixString(16)}@T${counter}';
  String get causeId => 'S${cause?.site?.toRadixString(16)}@T${cause?.counter}';

  @override
  String toString() => '${siteId}-${causeId} : ${data}';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is CausalAtom && cause == o.cause && clock == o.clock;
  }

  @override
  int get hashCode {
    var hash = 0;

    if (data is Map) {
      (data as Map).entries.forEach((e) => hash ^= e.key.hashCode ^ e.value.hashCode);
    } else if (data is List) {
      (data as List).forEach((e) => hash ^= e.hashCode);
    } else {
      hash = data.hashCode;
    }

    return clock.hashCode ^ hash ^ cause?.hashCode;
  }
}
