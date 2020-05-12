import 'package:sync_layer/timestamp/index.dart';

class Clock {
  Hlc _localTime;

  Clock([int site])
      : assert(site != null),
        _localTime = Hlc(DateTime.now().millisecondsSinceEpoch, 0, site);

  Hlc getHlc(int ms, int counter, int site) {
    return Hlc(ms, counter, site);
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
