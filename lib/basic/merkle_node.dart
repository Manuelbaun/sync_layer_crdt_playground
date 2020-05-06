final hashCode = 124;
final tempHashCode = 125;

class MerkleNode {
  List<MerkleNode> children;
  int hash = 0;

  MerkleNode([bool subchild = true, int radix = 36]) {
    if (subchild) children = List(radix);
  }

  // factory MerkleNode.fromMap(Map<String, dynamic> map, int radix) {
  //   final node = MerkleNode(true, radix);

  //   for (var ent in map.entries) {
  //     final key = ent.key;
  //     var value = ent.value;

  //     if (key != '#') {
  //       var pos = int.parse(key, radix: radix);

  //       if (value is Map) {
  //         // value =
  //         node.children[pos] = MerkleNode.fromMap(value.cast<String, dynamic>(), radix);
  //       } else if (value is num) {
  //         // the end of the tree
  //         node.children[pos] = MerkleNode(false, radix);
  //         node.children[pos].hash = value;
  //       }
  //     } else {
  //       node.hash = map['#'] as int;
  //     }
  //   }

  //   return node;
  // }

  // Map<String, dynamic> toMap() {
  //   var map = <String, dynamic>{};
  //   if (children != null) {
  //     for (var i = 0; i < children.length; i++) {
  //       if (children[i] != null) {
  //         final key = i.toRadixString(children.length);

  //         final res = children[i].toMap();

  //         // workaround, so the toJson() is map
  //         map[key] = res['_'] ?? res;
  //         // if (res['_'] == null) {
  //         //   map[key] = res;
  //         // } else {
  //         //   map[key] = res['_'];
  //         // }
  //       }
  //     }
  //   } else {
  //     return {'_': hash};
  //   }

  //   map['#'] = hash;
  //   return map;
  // }

  Map<int, dynamic> toMap() {
    var map = <int, dynamic>{};
    if (children != null) {
      for (var i = 0; i < children.length; i++) {
        if (children[i] != null) {
          final res = children[i].toMap();

          map[i] = res[tempHashCode] ?? res;
        }
      }
    } else {
      return {tempHashCode: hash};
    }

    map[hashCode] = hash;
    return map;
  }

  factory MerkleNode.fromMap(Map<int, dynamic> map, int radix) {
    final node = MerkleNode(true, radix);

    for (var i in map.keys) {
      var value = map[i];

      if (i != hashCode) {
        if (value is Map) {
          // value =
          node.children[i] = MerkleNode.fromMap(value.cast<int, dynamic>(), radix);
        } else if (value is num) {
          // the end of the tree
          node.children[i] = MerkleNode(false, radix);
          node.children[i].hash = value;
        }
      } else {
        node.hash = map[hashCode] as int;
      }
    }

    return node;
  }
}
