class MerkleNode {
  List<MerkleNode> children;
  int hash = 0;

  MerkleNode([bool subchild = true, int radix = 36]) {
    if (subchild) children = List(radix);
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{};
    if (children != null) {
      for (var i = 0; i < children.length; i++) {
        if (children[i] != null) {
          final key = i.toRadixString(children.length);

          final res = children[i].toMap();

          // workaround, so the toJson() is map
          if (res['_'] == null) {
            map[key] = res;
          } else {
            map[key] = res['_'];
          }
        }
      }
    } else {
      return {'_': hash};
    }

    map['#'] = hash;
    return map;
  }

  MerkleNode fromMap(Map<String, dynamic> map, int radix) {
    final node = MerkleNode(true, radix);

    for (var ent in map.entries) {
      final key = ent.key;
      final value = ent.value;

      if (key != '#') {
        var pos = int.parse(key, radix: radix);

        if (value is Map) {
          node.children[pos] = fromMap(value, radix);
        } else if (value is num) {
          // the end of the tree
          node.children[pos] = MerkleNode(false, radix);
          node.children[pos].hash = value;
        }
      } else {
        node.hash = map['#'] as int;
      }
    }

    return node;
  }
}
