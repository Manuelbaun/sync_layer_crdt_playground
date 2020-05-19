import 'package:sync_layer/types/abstract/logical_clock_base.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/logical_clock.dart';

import 'causal_entry.dart';

/// This is somewhat close to Ordered List CRDT
/// from Martin Kleppmann
/// the conflict insertion resoluction same as in
/// https://youtu.be/B5NULPSiOGw?t=2507

enum FilterSemantic { AND, OR }

class CausalTree<T> {
  CausalTree(this.site, {onChange})
      : localClock = LogicalClock(0),
        _onChange = onChange;

  int site;

  final void Function(CausalEntry<T> entry) _onChange;

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
  List<CausalEntry<T>> sequence = <CausalEntry<T>>[];

  // the local site cache, does not need to be the same in the cloud
  final yarns = <int, List<CausalEntry<T>>>{};

  /// SiteId -> TimeStamp, Kind of Version vector
  final weft = <int, int>{};

  /// New LogicalTime will increase monotonically. Therefore, an Atoms of the
  /// same site cannot have the same counter.
  LogicalClockBase localClock;

  Id _newID() {
    localClock = LogicalClock.send(localClock);
    return Id(localClock, site);
  }

  void _insert(CausalEntry<T> entry, {int index, bool sequenceRun = true}) {
    if (_allIds.contains(entry.id)) return;

    _allIds.add(entry.id);

    // set cause index, if null, then search!
    var causeIndex = index;
    causeIndex ??= sequence.indexWhere((e) => e.id == entry.cause);

    if (sequence.isEmpty || causeIndex >= sequence.length - 1) {
      sequence.add(entry);
    } else

    /// insert after cause
    if (causeIndex >= 0) {
      causeIndex += 1;

      /// checks if atom to insert and atom at causeIndex are siblings
      if (entry.cause == sequence[causeIndex].cause) {
        if (sequenceRun) {
          /// increase causeIndex and check if atom at causeIndex is left of current atom
          while (causeIndex < sequence.length && sequence[causeIndex].isLeftOf(entry)) {
            causeIndex++;
          }
        }
      }

      sequence.insert(causeIndex, entry);
    } else if (causeIndex < 0 && sequence.isNotEmpty) {
      pending.add(entry);

      /// TODO: mechanism to insert pending atom
      print('pending atom $entry');
      // throw AssertionError('Pending is not supported yet');
    }

    yarns[entry.site] ??= <CausalEntry<T>>[];
    yarns[entry.site].add(entry);

    if (_onChange != null) _onChange(entry);
  }

  // Add to deletedAtoms set
  void _delete(CausalEntry<T> entry, [int index]) {
    _deletedIds.add(entry.cause);
    _deletedIds.add(entry.id);
    _insert(entry, index: index);
  }

  void mergeRemoteEntriees(List<CausalEntry<T>> entries, [recvActive = true]) {
    for (final entry in entries) {
      /// normally
      if (recvActive) {
        localClock = LogicalClock.recv(localClock, entry.id.ts);
      }

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
      cause: parent?.id,
      data: value,
    );

    _insert(entry);
    return entry;
  }

  CausalEntry<T> push(T value) {
    final entry = CausalEntry<T>(
      _newID(),
      cause: sequence.isNotEmpty ? sequence.last.id : null,
      data: value,
    );

    _insert(entry, index: sequence.length);
    // maybe just add here?
    return entry;
  }

  void pop() {
    _delete(sequence.last, sequence.length);
  }

  CausalEntry<T> delete(CausalEntry<T> deleteEntry) {
    final entry = CausalEntry<T>(
      _newID(),
      cause: deleteEntry?.id,
      data: null,
    );

    _delete(entry);
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
    return sequence
        .where((entry) => !(entry.data == null || _deletedIds.contains(entry.id)))
        .map(((a) => a.data.toString()))
        .join('');
  }

  /// workaround to get a cleaned sequence without tombstone...
  /// filtered sequence
  List<CausalEntry<T>> value() {
    return sequence.where((entry) => !(entry.data == null || _deletedIds.contains(entry.id))).toList();
  }
}
