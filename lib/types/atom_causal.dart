import 'package:sync_layer/basic/hashing.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'atom_base.dart';

class CausalAtom<T> implements AtomBase<T>, Comparable<CausalAtom> {
  /// the clock is the atom [clock]
  @override
  final LogicalClock clock;

  /// the cause is the clock of the causing atom => [clock]
  final LogicalClock cause;

  int get site => clock.site;
  int get counter => clock.counter;

  @override
  final T data;

  CausalAtom(this.clock, this.cause, this.data) : assert(clock != null);
  // assert(cause != null ?? clock.runtimeType != cause.runtimeType, 'clock and cause need to be the same type!');

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
  @override
  int compareTo(CausalAtom other) {
    // if cause is equal => siblings
    if (cause == other.cause) {
      if (clock > other.clock) {
        return -1;
      } else if (clock == other.clock) {
        // TODO: test if this compare is correct!
        return other.site - site;
      }
    }

    return 0;
  }

  String get clockString => clock.toStringRON();
  String get causeString => cause?.toStringRON();

  @override
  String toString() => '${clockString}::${causeString} : ${data}';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    /// TODO: what if cause is null???
    return o is CausalAtom && clock == o.clock && cause == o.cause && data == o.data;
  }

  @override
  int get hashCode {
    return clock.hashCode ^ nestedHashing(data) ^ cause?.hashCode;
  }
}
