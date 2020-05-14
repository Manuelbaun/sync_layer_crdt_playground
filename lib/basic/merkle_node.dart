final _hashCode = 124;
final _tempHashCode = 125;

class MerkleNode {
  List<MerkleNode> children;
  int hash = 0;

  MerkleNode([bool subchild = true, int radix = 36]) {
    if (subchild) children = List(radix);
  }

  Map<int, dynamic> toMap() {
    var map = <int, dynamic>{};
    if (children != null) {
      for (var i = 0; i < children.length; i++) {
        if (children[i] != null) {
          final res = children[i].toMap();

          map[i] = res[_tempHashCode] ?? res;
        }
      }
    } else {
      return {_tempHashCode: hash};
    }

    map[_hashCode] = hash;
    return map;
  }

  factory MerkleNode.fromMap(Map<int, dynamic> map, [int radix = 36]) {
    final node = MerkleNode(true, radix);

    for (var i in map.keys) {
      var value = map[i];

      if (i != _hashCode) {
        if (value is Map) {
          // value =
          node.children[i] = MerkleNode.fromMap(value.cast<int, dynamic>(), radix);
        } else if (value is num) {
          // the end of the tree
          node.children[i] = MerkleNode(false, radix);
          node.children[i].hash = value;
        }
      } else {
        node.hash = map[_hashCode] as int;
      }
    }

    return node;
  }
}
