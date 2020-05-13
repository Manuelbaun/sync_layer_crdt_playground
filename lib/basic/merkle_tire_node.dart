import 'dart:typed_data';
import 'package:sync_layer/timestamp/index.dart';

import 'merkle_node.dart';

/// dart does not have int32, so when xor, it uses 64 bits, which then are representet different
/// on the vm then in the browser. JavaScript uses 32 bits, when doing bit operations
int convHash(int hash) => (ByteData(4)..setInt32(0, hash)).getInt32(0);

class MergeSkip {
  List merged = [];
  List skipped = [];
}

class MerkleTrie {
  final MerkleNode root;
  final int radix;
  final keys = <int>{}; // This is quick and dirty, FIXME

  MerkleTrie([this.radix = 36, MerkleNode root]) : this.root = root ?? MerkleNode();

  int get hash => root.hash;

  MergeSkip build(List<Hlc> hlcs) {
    final ms = MergeSkip();
    for (var h in hlcs) {
      final key = h.radixTime(radix);

      if (!keys.contains(h.counter)) {
        _insert(root, key, h.hashCode, 0);
        root.hash = convHash(root.hash ^ h.hashCode);
        ms.merged.add(h.toString());
        keys.add(h.counter);
      } else {
        ms.skipped.add(h.toString());
      }
    }
    return ms;
  }

  factory MerkleTrie.fromMap(Map<int, dynamic> map, [int radix = 36]) {
    var root = MerkleNode(true, radix);
    root = MerkleNode.fromMap(map, radix);

    final tree = MerkleTrie(radix, root);
    return tree;
  }

  MerkleNode _insert(MerkleNode node, String key, int hash, int counter) {
    if (key.length == counter) return node;

    var pos = int.parse(key[counter], radix: radix);
    var nextNode = node.children[pos];
    final nextCounter = counter + 1;

    // create subnodes
    nextNode ??= (key.length == nextCounter) ? MerkleNode(false) : MerkleNode();
    nextNode = _insert(nextNode, key, hash, nextCounter);

    // make hash
    nextNode.hash = convHash(nextNode.hash ^ hash);
    node.children[pos] = nextNode;

    return node;
  }

  /// this returns the first timestamp, which is not equal
  String diff(MerkleTrie remote) {
    if (hashCode == remote.hashCode) return null;
    return _diff(root, remote.root);
  }

  List<int> _keys(MerkleNode node) {
    if (node == null || node.children == null) return [];

    final keys = <int>[];
    for (var rad = 0; rad < radix; rad++) {
      if (node.children[rad] != null) keys.add(rad);
    }

    return keys;
  }

  Iterable<int> _getNodeKeys(MerkleNode local, MerkleNode remote) {
    return Set<int>.from(_keys(local))..addAll(_keys(remote));
  }

  // add set to the nodes
  String _diff(MerkleNode local, MerkleNode remote) {
    if (local.hash == remote.hash) return null;

    var localNode = local;
    var remoteNode = remote;
    var searchKey = '';

    while (true) {
      final keys = _getNodeKeys(localNode, remoteNode);

      int diffKey;
      for (var key in keys) {
        final next1 = (localNode != null) ? localNode.children[key] : null;
        final next2 = (remoteNode != null) ? remoteNode.children[key] : null;

        if (next1 == null || next2 == null || next1.hash != next2.hash) {
          diffKey = key;
          break;
        }
      }

      if (diffKey == null) {
        return searchKey;
      }

      searchKey += diffKey.toRadixString(radix);

      localNode = (localNode != null) ? localNode.children[diffKey] : null;
      remoteNode = (remoteNode != null) ? remoteNode.children[diffKey] : null;
    }
  }

  /// returns local and remote differences:
  /// when present in local, that means its missing in local
  /// when present in remote, that means its missing in remote
  ///
  KeysLR getDifferences(MerkleTrie remote) => _diffKeyLR(root, remote.root);

  KeysLR _diffKeyLR(MerkleNode local, MerkleNode remote, [String currKey = '']) {
    if (local.hash == remote.hash) return null;

    final rlKeys = KeysLR();
    final keys = _getNodeKeys(local, remote);

    for (final key in keys) {
      final nextLocal = local.children[key];
      final nextRemote = remote.children[key];

      if (nextLocal == null) {
        rlKeys.local.add(currKey);
      } else if (nextRemote == null) {
        rlKeys.remote.add(currKey);
      } else if (nextLocal.hash != nextRemote.hash) {
        final res = _diffKeyLR(nextLocal, nextRemote, currKey + key.toRadixString(radix));

        if (res != null) {
          rlKeys.local.addAll(res.local);
          rlKeys.remote.addAll(res.remote);
        }
      }
    }

    // both,left and right, dont have the full data, => both need to merge that time!
    if (keys.isEmpty && local.hash != remote.hash) {
      rlKeys.local.add(currKey);
      rlKeys.remote.add(currKey);
    }

    return rlKeys;
  }

  // TODO: fix map<int, dynamic> does not work as json!!
  // String toJson() {
  //   return json.encode(root.toMap());
  // }

  // String toJsonPretty() {
  //   var encoder = JsonEncoder.withIndent('  ');
  //   return encoder.convert(root.toMap());
  // }

  Map<int, dynamic> toMap() {
    return root.toMap();
  }
}

class KeysLR {
  List<String> local = [];
  List<String> remote = [];
}
