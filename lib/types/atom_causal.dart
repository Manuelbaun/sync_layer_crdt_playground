import 'package:sync_layer/basic/hashing.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'atom_base.dart';

enum RelationShip { Sibling, CausalLeft, CausalRight, Unknown, Identical }

/// for a causal atom to work, the clock must be from the same type,
/// no mix of Hlc and logicaltime
///
/// Atoms should be not mutable,
/// otherwise recalculate the hash!!!!
class CausalAtom<T> implements AtomBase<T>, Comparable<CausalAtom> {
  CausalAtom(this.clock, this.cause, this.data) : assert(clock != null) {
    _hashcode = clock.hashCode ^ nestedHashing(data) ^ (cause?.hashCode ?? 0);
  }
  int _hashcode;

  /// its the clocks since the clock should be unique!
  /// TODO: Test and reconsider id;
  @override
  int get id => clock.hashCode;

  /// the clock is the atoms [clock] / id?
  @override
  final LogicalClock clock;

  /// the cause is the clock of the causing atom => [clock]
  final LogicalClock cause;
  int get causeId => cause?.hashCode;

  int get site => clock.site;
  int get counter => clock.counter;

  @override
  final T data;

  static bool isSibling(CausalAtom a, CausalAtom b) => a.causeId == b.causeId;

  /// all comparison are related to Causal Atom [a]
  static RelationShip getRelationshipOf_A_to_B(CausalAtom a, CausalAtom b) => a.relatesTo(b);

  /// all comparison are related to Causal Atom [a]
  RelationShip relatesTo(CausalAtom other) {
    if (this == other) return RelationShip.Identical;
    if (causeId == null && other.causeId == null) return RelationShip.Unknown;

    if (causeId == null && other.causeId != null) {
      if (id == other.causeId) return RelationShip.CausalLeft;
    }

    if (causeId != null && other.causeId == null) {
      if (causeId == other.id) return RelationShip.CausalRight;
    }

    if (causeId == other.causeId) return RelationShip.Sibling;

    // is this right
    return RelationShip.Unknown;
  }

  /// This function only to be used in the context when two atoms are siblings to the same cause.
  /// then a loop should call this function to compare if the atom on the left side
  /// is still
  static bool leftIsLeft(CausalAtom left, CausalAtom other) {
    if (left.site == other.site) {
      return left.clock < other.clock;
    }
    return left.site < other.site;

    // if (left.clock > right.clock) {
    //   return true;
    // } else if (left.clock == right.clock) {
    //   return left.site > right.site;
    // }
    // return false;
  }

  // return site == other.site ? clock < other.clock : site < other.site;
  bool isLeftOf(CausalAtom other) {
    return clock == other.clock ? site > other.site : clock > other.clock;
    // if (site == other.site) {
    //   return clock < other.clock;
    // }
    // return site < other.site;
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

  String get selfString => clock.toStringRON();
  String get causeString => cause?.toStringRON();

  @override
  String toString() => '${selfString}->${causeString} : ${data}';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is CausalAtom && hashCode == o.hashCode;
  }

  @override
  int get hashCode => _hashcode;
}
