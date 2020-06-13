import 'dart:async';

import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';
import 'package:sync_layer/crdts/causal_tree/causal_tree.dart';
import 'package:sync_layer/types/abstract/atom_base.dart';
import 'package:sync_layer/types/abstract/id_base.dart';
import 'package:sync_layer/types/object_reference.dart';

import 'abstract/acess_proxy.dart';
import 'abstract/syncable_base.dart';

abstract class SyncableCausalTreeBase extends SyncableBase {}

/// Actually, this is a syncable ordered list!!! like it is implemented
/// the Delete operator does not delete the entries, rather tombstone with
/// anther entry
///
///
/// At the moment [SyncableCausalTree] atom in creation order
/// no pending sync mechanism yet
///
///
/// TODO:
/// * Pending sync
/// * transaction
/// * tombstone
/// * abstract causal tree
/// * rename in ordered list?
/// * Create own Acessor
class SyncableCausalTree<T, THIS extends SyncableCausalTreeBase> extends SyncableCausalTreeBase {
  SyncableCausalTree(this.proxy, this.id)
      : assert(proxy != null, 'Accessor prop cannot be null'),
        assert(id != null, 'Id cannot be null') {
    _internal = CausalTree<T>(
      proxy.site,
      onChange: _onTreeChange,
      onLocalUpdate: _ontreeLocalUpdate,
    );
  }

  /// the acutal causal tree => orderted list
  CausalTree<T> _internal;

  final _transactList = <CausalEntry<T>>[];
  var _isTransaction = false;

  @pragma('vm:prefer-inline')
  void _sendUpate(List<CausalEntry<T>> data) {
    final a = proxy.mutate(id, data);
  }

  /// create atom from local entry
  void _ontreeLocalUpdate(CausalEntry<T> entry) {
    if (_isTransaction == false) {
      _sendUpate([entry]);
    } else {
      _transactList.add(entry);
    }
  }

  /// get the values,which are note delete.
  void _onTreeChange() {
    if (_isTransaction == false) {
      _filteredEntries = _internal.value;
      _filteredValues = _filteredEntries.map(_convertEntry2Data).toList();
      _controller.add(_filteredValues);
    }
  }

  final _controller = StreamController<List<T>>.broadcast();

  /// [stream] trigger, when values are changed. and return only the
  /// 'filtered' [values]
  @override
  Stream<List<T>> get onChange => _controller.stream;

  /// this is a workaround to get index and entries mapped
  List<CausalEntry<T>> _filteredEntries = <CausalEntry<T>>[];

  /// gets the real tree entries,  [map],[list], a [primitives] or [objectReference]
  /// try using values
  List<CausalEntry<T>> get entries => _filteredEntries;
  List<CausalEntry<T>> get entriesUnfiltered => _internal.sequence;
  List<CausalEntry<T>> get entryValue => _internal.value;

  /// if called, all [SyncableObjectRef] will be looked up and return Syncable Objects
  List<T> _filteredValues = <T>[];

  /// returns the values, deleted are filtered out.
  List<T> get values => _filteredValues;

  @override
  final AccessProxy proxy;

  /// The object type
  @override
  int get type => proxy.type;

  /// Marks if the object is deleted!
  /// not implemented yet
  @override
  bool get tombstone {
    return false;
  }

  /// not implemented yet
  @override
  void delete() {
    throw AssertionError('not implemented yet');
  }

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

  // TODO: fix me, with types..
  @pragma('vm:prefer-inline')
  T _convertEntry2Data(dynamic e) {
    var data = e.data;

    if (_syncableObjectsRefs.containsKey(e.id)) {
      data = _getSyncableRef(e.id);
    } else if (data is SyncableObjectRef) {
      data = proxy.refLookup(e.data);
      _setSyncableRef(e.id, data);
    } else {
      data = data as T;
    }
    return data;
  }

  /// will use an list
  @override
  void transact(void Function(THIS self) func) {
    _isTransaction = true;
    func(this as THIS);
    _isTransaction = false;

    _sendUpate([..._transactList]);
    _transactList.clear();
    _onTreeChange();
  }

  final _history = <AtomBase>{};
  List<AtomBase> get history => _history.toList(growable: false)..sort();

  ///
  /// ### [applyRemoteAtom] => for remote!
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
  int applyRemoteAtom(AtomBase atom, {bool isLocalUpdate = true}) {
    final entries = (atom.data as List)
        .map<CausalEntry<T>>((e) => CausalEntry<T>(e.id, cause: e.cause, data: e.data as T))
        .toList();

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
  bool insert(int index, T value) {
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
  bool push(T value) {
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
