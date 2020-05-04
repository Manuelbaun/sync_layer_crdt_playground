import 'package:sync_layer/basic/hlc.dart';
import 'package:sync_layer/basic/merkle_tire_node.dart';

class Clock {
  Hlc _localTime;

  final MerkleTrie _merkleRoot;
  MerkleTrie get merkle => _merkleRoot;

  Clock([String nodeId, MerkleTrie trie])
      : _merkleRoot = trie ?? MerkleTrie(),
        _localTime = Hlc(null, 0, nodeId ?? '0');

  Hlc getHlc(int ms, int counter, String node) {
    return Hlc(ms, counter, node);
  }

  Hlc getForSend() {
    _localTime = Hlc.send(_localTime);
    return _localTime;
  }

  void fromReveive(Hlc incoming) {
    _localTime = Hlc.recv(_localTime, incoming);
  }
}
