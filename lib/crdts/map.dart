import 'dart:convert';

import 'package:sync_layer/basic/cuid.dart';

import 'package:sync_layer/basic/hlc.dart';

import 'atom.dart';

///
/// A CRDT Map implements the Last Writer Wins Strategy only
/// This map can be used to represent a Row in a database table
///
class CRDTMap<K, V> {
  final String objId;

  // the highes of all _clocks!!
  Hlc _timestamp;

  // stores the value
  Map<K, V> _kv;

  // maybe can be made different
  // stores the Hlc for each Key
  Map<K, Hlc> _kv_clocks;

  // getters
  // int get owner => _owner;
  Hlc get hlc => _timestamp;
  Map<K, V> get map => _kv;

  CRDTMap([String objId]) : objId = objId ?? newCuid() {
    // TODO: get latest hlc from somewhere!!!
    // todo objId,
    _kv = <K, V>{};
    _kv_clocks = <K, Hlc>{};
  }

  factory CRDTMap.fromMap(Map<String, V> map) {
    return CRDTMap(map['objId'] as String)
      .._kv = (map['kv'] as Map<K, V>)
      .._kv_clocks = (map['kv_clocks'] as Map<K, Hlc>);
  }

  /// This funtion just overrides the map value
  void operator []=(K key, V value) => set(key, value);

  // TODO set Multi key, values as one update
  Atom set(K key, V value) {
    _kv[key] = value;
    _timestamp = Hlc.send(_timestamp);
    _kv_clocks[key] = _timestamp;

    // TODO: call Db-Hook!
    // return SyncMessage(objId, hlc, {_kv[key]: value});
  }

  /// get value by key. Same property as the underlaying map
  V operator [](Object key) => get(key);
  V get(K key) => _kv[key];

  void mergeRemote(List<Atom> messages) {
    for (final msg in messages) {
      // TODO: call Db-Hook!

      /// only merge if Atom of remote > then local

      for (final kv in msg.value.entries) {
        final key = kv.column;
        final value = kv.value;

        // if localtime is smaller..
        if (_kv_clocks[key] < msg.ts) {
          _kv[key] = value;
          _kv_clocks[key] = msg.ts;
        } else if (_kv[key] == null)
        // if no local entry exist
        {
          _kv[key] = value;
          _kv_clocks[key] = msg.ts;
        } else {
          //TODO: else ignore incoming update?
          print('...ignore incoming remote messages: ${msg.ts}');
        }
      }
    }
  }

  bool superset(CRDTMap m) {
    return false;
    // if (_kv.length < m.map.length) return false;

    // for (final remoteEntry in m.map.entries) {
    //   final local = _kv[remoteEntry.key];
    //   if (local == null) {
    //     return false;
    //   } else if (remoteEntry.value.id > local.id) {
    //     return false;
    //   }
    // }

    // return true;
  }

  bool validate() {
    // think about a validation
    return false;
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return hashCode == (o as CRDTMap).hashCode;
  }

  static bool deepEqual(CRDTMap lhs, CRDTMap rhs) {
    return lhs.hashCode == rhs.hashCode;
  }

  @override
  int get hashCode {
    var hashcode = 0;

    for (final entry in _kv.entries) {
      hashcode ^= (entry.key.hashCode) ^ entry.value.hashCode;
    }

    return hashcode;
  }

  @override
  String toString() {
    final obj = {'id': objId, 'ts': hlc, 'kv': _kv};
    return json.encode(obj);
  }
}
