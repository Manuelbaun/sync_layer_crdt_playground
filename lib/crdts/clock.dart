import 'package:sync_layer/basic/hlc.dart';

class Clock {
  Hlc _localTime;

  Clock([String nodeId]) : _localTime = Hlc(null, 0, nodeId ?? '0');

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
