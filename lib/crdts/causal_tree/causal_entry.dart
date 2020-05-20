import 'package:sync_layer/types/abstract/id_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'causal_entry_base.dart';

/// for a causal atom to work, the clock must be from the same type,
/// no mix of Hlc and logicaltime
///
/// Atoms should be not mutable,
/// otherwise recalculate the hash!!!!
/// , Comparable<CausalEntry> removed Comparable!!
///
class CausalEntry<T> implements CausalEntryBase {
  CausalEntry(this.id, {this.data, this.cause}) : assert(id != null, 'id must be provided') {
    _hashcode = id.hashCode ^ (cause?.hashCode ?? 0); //^ nestedHashing(data);
  }
  int _hashcode;

  /// the [id] of this entry, is also its logical lock
  @override
  final IdBase id;

  @override
  LogicalClockBase get ts => id.ts;

  @override
  int get site => id.site;

  @override
  final IdBase cause;

  @override
  LogicalClockBase get causeTs => cause.ts;

  @override
  int get causeSite => cause.site;

  @override
  final T data;

  @override
  bool isSibling(CausalEntryBase other) => cause == other.cause;

  /// all comparison are related to Causal Atom [a]
  /// should be sorted by frequency of occurrence
  @override
  RelationShip relatesTo(CausalEntryBase other) {
    /// is this relevant?
    if (this == other) return RelationShip.Identical;

    if (cause == null && other.cause == null) return RelationShip.Unknown;
    if (cause == other.cause) return RelationShip.Sibling;

    if (cause == null && other.cause != null) {
      if (id == other.cause) return RelationShip.CausalLeft;
    }

    if (cause != null && other.cause == null) {
      if (cause == other.id) return RelationShip.CausalRight;
    }

    // is this right ?
    return RelationShip.Unknown;
  }

  /// This function only to be used in the context when two atoms are [siblings] to the same cause.
  /// then a loop should call this function to compare if the atom on the left side
  /// is still,
  /// is not to be used, when comparing two atoms. These atoms do have cause and effekt relationship
  // static bool leftIsLeft(CausalAtom left, CausalAtom other) {
  //   return left.clock == other.clock ? left.site > other.site : left.clock > other.clock;
  // }

  /// This function only to be used in the context when two atoms are [siblings] to the same cause.
  /// then a loop should call this function to compare if the atom on the left side
  /// is still,
  /// is not to be used, when comparing two atoms. These atoms do have cause and effekt relationship
  @override
  bool isLeftOf(CausalEntryBase o) => id.ts == o.id.ts ? id.site > o.id.site : id.ts > o.id.ts;

  bool operator <(o) => (o is CausalEntryBase) && id.ts == o.id.ts ? id.site < o.id.site : id.ts < o.ts;

  bool operator >(o) => (o is CausalEntryBase) && id.ts == o.id.ts ? id.site > o.id.site : id.ts > o.ts;

  @override
  String toString() => '${id.toRONString()}->${cause?.toRONString()}:' + '$data'.padLeft(4, ' ');

  @override
  int get hashCode => _hashcode;
  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is CausalEntry && hashCode == o.hashCode;
  }
}
