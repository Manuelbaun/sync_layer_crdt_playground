import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/logical_clock.dart';

import 'causal_entry.dart';

/// This is somewhat close to Ordered List CRDT
/// from Martin Kleppmann
/// the conflict insertion resoluction same as in
/// https://youtu.be/B5NULPSiOGw?t=2507

enum FilterSemantic { AND, OR }
typedef VoidCallback = void Function();
typedef OnUpdate<T> = void Function(CausalEntry<T> update);

class CausalTree<T> {
  CausalTree(this.site, {this.onChange, this.onLocalUpdate}) : localClock = LogicalClock(0) {
    root = CausalEntry(Id(localClock, -1), data: null, cause: null);
  }

  int site;
  CausalEntry root;

  /// [onchange] gets triggerd as void callback, if a new entry changed the [CausalTree]
  final VoidCallback onChange;

  /// [onLocalUpdate] gets triggered if a local change happend and provides with that entry
  final OnUpdate onLocalUpdate;

  // should we use deltedAtoms?
  final Set<Id> _deletedIds = {};
  final Set<Id> _allIds = {};

  bool exist(Id id) => _allIds.contains(id);
  bool isDeleted(Id id) => _deletedIds.contains(id);

  /// the length of the added entries - deletedEntries
  int get length => _allIds.length - _deletedIds.length;
  int get deletedLength => _deletedIds.length;
  int get fullLength => _allIds.length;

  // if atoms could not find the cause in this tree, but belong to this one
  final pending = <CausalEntry<T>>[];

  /// this sequence will be the same on all synced sites
  final List<CausalEntry<T>> sequence = <CausalEntry<T>>[];

  // the local site cache, does not need to be the same in the cloud
  final yarns = <int, List<CausalEntry<T>>>{};

  /// SiteId -> TimeStamp, Kind of Version vector
  final weft = <int, int>{};

  /// New LogicalTime will increase monotonically. Therefore, an Atoms of the
  /// same site cannot have the same counter.
  LogicalClockBase localClock;

  @pragma('vm:prefer-inline')
  Id _newID() {
    localClock = LogicalClock.send(localClock);
    return Id(localClock, site);
  }

  /// returns
  /// triggers onChange only when successfull
  /// TODO:
  /// * trigger pending ?
  void _insert(CausalEntry<T> entry, {int index}) {
    if (_allIds.contains(entry.id)) return;

    _allIds.add(entry.id);

    // set cause index, if null, then search!
    var causeIndex = index;
    causeIndex ??= sequence.indexWhere((e) => e.id == entry.cause);

    /// if remote entry gets here, needs to check wheter cause is root
    if (entry.cause == root.id) causeIndex = 0;

    // with root in sequence isEmpty is never true
    if (causeIndex >= sequence.length - 1 || sequence.isEmpty) {
      sequence.add(entry);
    } else

    /// insert after cause
    if (causeIndex >= 0) {
      /// if entrys cause is root id, then dont increate causeIndex
      if (entry.cause != root.id) causeIndex += 1;

      /// checks if the next entry is a sibling to the current entry
      if (entry.isSibling(sequence[causeIndex])) {
        /// increase causeIndex and check if atom at causeIndex is left of current atom
        while (causeIndex < sequence.length && sequence[causeIndex].isLeftOf(entry)) {
          causeIndex++;
        }
      }

      sequence.insert(causeIndex, entry);
    }

    // if not found, => pending, will insert as soon as the right entry arrive
    // TODO: * pending impl
    if (causeIndex < 0 && sequence.isNotEmpty) {
      pending.add(entry);
      print('pending atom $entry => not working yet');
    }

    /// else successfull added
    else {
      // yarns come later
      // yarns[entry.site] ??= <CausalEntry<T>>[];
      // yarns[entry.site].add(entry);

      if (onChange != null) onChange();
    }
  }

  /// Adds to deleted ids set
  /// and insert the delete entry to the trie
  @pragma('vm:prefer-inline')
  void _delete(CausalEntry<T> entry, {int index}) {
    _deletedIds.add(entry.cause);
    _deletedIds.add(entry.id);
    _insert(entry, index: index);
  }

  void mergeRemoteEntries(List<CausalEntry<T>> entries) {
    for (final entry in entries) {
      /// increase local time, get the max!
      localClock = LogicalClock.recv(localClock, entry.id.ts);

      if (entry.data == null) {
        _delete(entry);
      } else {
        _insert(entry);
      }
    }
  }

  CausalEntry<T> insert(CausalEntry<T> parent, T value) {
    final entry = CausalEntry<T>(
      _newID(),
      cause: parent?.id ?? root.id,
      data: value,
    );

    _insert(entry, index: parent == null ? 0 : null);

    if (onLocalUpdate != null) onLocalUpdate(entry);

    return entry;
  }

  CausalEntry<T> push(T value) {
    final entry = CausalEntry<T>(
      _newID(),
      cause: sequence.isNotEmpty ? sequence.last.id : root.id,
      data: value,
    );

    _insert(entry, index: sequence.length);
    if (onLocalUpdate != null) onLocalUpdate(entry);

    return entry;
  }

  CausalEntry<T> delete(CausalEntry<T> deleteEntry) {
    final entry = CausalEntry<T>(
      _newID(),
      cause: deleteEntry?.id,
      data: null,
    );

    _delete(entry);

    if (onLocalUpdate != null) onLocalUpdate(entry);
    return entry;
  }

  /// [semantic] is set to [OR] by default, means either [logicalTime] or [siteIds] will be filterd by
  ///
  /// if set to **AND**: it is expected to use one or both [tsMin, tsMax] **and** the [siteid/s]
  ///
  /// When filter by time:  **tsMin <= ts < tsMax**
  /// [tsMin] is inclusive
  /// [tsMax] is not included anymore
  ///
  List<CausalEntry> filtering({
    LogicalClockBase tsMin,
    LogicalClockBase tsMax,
    Set<int> siteIds,
    bool containsDeleted = false,
    semantic = FilterSemantic.OR,
  }) {
    assert(
      !(tsMax == null && tsMin == null && siteIds == null),
      'all filter are null, cannot filter by something',
    );

    /// test, that tsMin/Max and _localClock are of same logical clock type!
    /// cant compare Hlc with LogicalClock
    if (tsMin != null) assert(tsMin.runtimeType == localClock.runtimeType);
    if (tsMax != null) assert(tsMax.runtimeType == localClock.runtimeType);

    var atoms = <CausalEntry>[];

    for (var entry in sequence) {
      var hasTs = _filterTimestamp(entry, tsMin, tsMax);
      var hasId = _filterSiteIds(entry, siteIds);
      var isDeleted = _filterIsDelete(entry);

      var should = false;
      if (semantic == FilterSemantic.OR) {
        should = (hasTs || hasId) && !isDeleted;
      } else {
        should = hasTs && hasId && !isDeleted;
      }

      if (should) atoms.add(entry);
    }

    return atoms;
  }

  /// returns [false] if tsMin [AND] tsMax is [null], else check the time cases
  bool _filterTimestamp(CausalEntry<T> entry, LogicalClockBase tsMin, LogicalClockBase tsMax) {
    if (tsMin == null && tsMax == null) return false;

    if (tsMin != null && tsMax != null) {
      return tsMin <= entry.ts && entry.ts < tsMax;
    }

    if (tsMin != null) return tsMin <= entry.ts;
    if (tsMax != null) return entry.ts < tsMax;

    throw AssertionError('should never be reached');
  }

  /// returns true if data is null or the atom is deleted
  bool _filterIsDelete(CausalEntry<T> entry) {
    return entry.data == null || _deletedIds.contains(entry.id);
  }

  /// returns false if siteid is null or does not contain the id
  bool _filterSiteIds(CausalEntry<T> entry, Set<int> siteid) {
    return siteid == null ? false : siteid.contains(entry.site);
  }

  @override
  String toString() {
    return sequence.toString();
  }

  String toStringData() {
    return sequence.map((e) => e.data).toString();
  }

  /// workaround to get a cleaned sequence without tombstone...
  /// filtered sequence
  List<CausalEntry<T>> get value {
    return sequence.where((entry) {
      return !(entry.data == null || _deletedIds.contains(entry.id));
    }).toList();
  }
}
