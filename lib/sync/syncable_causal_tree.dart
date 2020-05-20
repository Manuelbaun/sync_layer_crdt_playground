import 'dart:async';

import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';
import 'package:sync_layer/crdts/causal_tree/causal_tree.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';
import 'package:sync_layer/types/object_reference.dart';

import 'abstract/acess_proxy.dart';
import 'abstract/syncable_base.dart';

/// Actually, this is a syncable ordered list!!!
/// like it is implemented
///
/// The causal tree, handels its one entries ... => how to work with this??
///
/// At the moment [SyncableCausalTree] atom in creation order
/// no pending sync mechanism yet
///
///
/// TODO:
/// * Object reference
/// * Pending sync
/// * tombstone
/// * abstract causal tree
/// * rename in ordered list?
class SyncableCausalTree<T> extends SyncableBase {
  SyncableCausalTree(this.proxy, this.id)
      : assert(proxy != null, 'Accessor prop cannot be null'),
        assert(id != null, 'Id cannot be null') {
    tombstone = false;

    _internal = CausalTree(
      proxy.site,
      onChange: _onTreeChange,
      onLocalUpdate: _ontreeLocalUpdate,
    );
  }

  /// create atom from local entry
  void _ontreeLocalUpdate(entry) {
    final a = proxy.update(id, entry, true);

    
  }

  /// get the values,which are note delete.
  void _onTreeChange() {
    _filteredEntries = _internal.value;
    _filteredValues = _filteredEntries.map(_convertEntry2Data).toList();
    _controller.add(_filteredValues);
  }

  final _controller = StreamController<List<T>>();
  Stream<List<T>> get stream => _controller.stream;

  CausalTree<T> _internal;

  /// this is a workaround to get index and entries mapped
  List<CausalEntry<T>> _filteredEntries = <CausalEntry<T>>[];

  /// gets the real tree entries,  [map],[list], a [primitives] or [objectReference]
  /// try using values
  List<CausalEntry<T>> get entries => _filteredEntries;
  List<CausalEntry<T>> get entriesUnfiltered => _internal.sequence;

  /// if called, all [ObjectReference] will be looked up and return Syncable Objects
  List<T> _filteredValues = <T>[];
  List<T> get values => _filteredValues;

  @override
  final AccessProxy proxy;

  /// The object type
  @override
  int get type => proxy.type;

  /// Marks if the object is deleted!
  @override
  bool tombstone;

  /// Object Id, Like RowId or Index in a Database, etc..
  @override
  final String id;

  @override
  String toString() => 'SyncableCausalTree(id: $id, site: ${proxy.site}, values: $values)';

  /// gets the last Updated TS and also site!
  @override
  IdBase get lastUpdated => _lastUpdated;
  IdBase _lastUpdated;

  final Map<IdBase, SyncableBase> _syncableObjectsRefs = {};

  /// Internal get and setter
  @pragma('vm:prefer-inline')
  SyncableBase _getSyncableRef(IdBase key) => _syncableObjectsRefs[key];

  @pragma('vm:prefer-inline')
  void _setSyncableRef(IdBase key, SyncableBase obj) => _syncableObjectsRefs[key] = obj;

  @pragma('vm:prefer-inline')
  dynamic _syncableBaseCheck(dynamic value) {
    if (value is SyncableBase) {
      return (value as SyncableBase).toObjectRef();
    }

    return value;
  }

  @pragma('vm:prefer-inline')
  dynamic _convertEntry2Data(CausalEntry e) {
    var data = e.data;

    if (_syncableObjectsRefs.containsKey(e.id)) {
      data = _getSyncableRef(e.id);
    } else if (data is ObjectReference) {
      data = proxy.objectLookup(e.data);
      _setSyncableRef(e.id, data);
    }

    return data;
  }

  /// will use an list
  @override
  void transact(void Function(SyncableBase ref) func) {
    throw AssertionError('not supported yet');
  }

  final _history = <AtomBase>{};
  List<AtomBase> get history => _history.toList(growable: false)..sort();

  ///
  /// ### [applyAtom] => for remote!
  ///
  /// TODO: * think about remote and local update state
  /// * isLocalUpdate
  ///
  /// applies atom and returns
  /// * returns [ 2] : if apply successfull
  /// * returns [ 1] : if atom clock is equal to current => same atom
  /// * returns [ 0] : if atom is older then current
  /// * returns [-1] : if nothing applied => should never happen
  ///
  @override
  int applyAtom(AtomBase atom, {bool isLocalUpdate = true}) {
    final entries = (atom.data is List) ? atom.data as List<CausalEntry<T>> : <CausalEntry<T>>[atom.data];

    // if atom did not exist, add and merge
    if (_history.add(atom)) {
      // update time;
      if (_lastUpdated == null || _lastUpdated < atom.id) _lastUpdated = atom.id;
      // update causal tree
      _internal.mergeRemoteEntries(entries);
      return 2;
    }
    return 0;
  }

  /// main functionality
  /// TODO: think
  bool insert(int index, dynamic value) {
    assert(index >= 0, 'cant insert negative index');

    /// check if it is syncable object
    value = _syncableBaseCheck(value);

    if (index <= 0) {
      _internal.insert(null, value);
    } else if (index >= _filteredEntries.length) {
      _internal.push(value);
    } else {
      final parent = _filteredEntries[index - 1];
      _internal.insert(parent, value);
    }

    return true;
  }

  /// todo: change to push! when refactor works again!
  bool add(dynamic value) {
    /// check if it is syncable object
    value = _syncableBaseCheck(value);
    _internal.push(value);

    return false;
  }

  void pop() {
    if (_filteredEntries.isNotEmpty) {
      removeAt(_filteredEntries.length - 1);
    }
  }

  bool removeAt(int index) {
    final cause = _filteredEntries[index];
    _internal.delete(cause);
    return false;
  }

  dynamic getAtIndex(int index) {
    return _filteredEntries[index];
  }
}
