import 'package:sync_layer/basic/hlc.dart';

class Clock {
  Hlc _localTime;

  Clock([String nodeId])
      : assert(nodeId != null),
        _localTime = Hlc(null, 0, nodeId);

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

  // ts key in  minutes to logical!
  /// TODO: Refactor, where its actually made!
  int tsKeyToMillisecond(String tsKey) {
    return (int.parse(tsKey, radix: 36) * 60000);
  }
}
