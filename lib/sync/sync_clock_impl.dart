import 'package:sync_layer/types/hybrid_logical_clock.dart';

/// TODO: Rename into sync_clock_impl!
/// implements SyncLayerClock
class Clock {
  HybridLogicalClock _localTime;

  Clock([int site])
      : assert(site != null),
        _localTime = HybridLogicalClock(DateTime.now().millisecondsSinceEpoch, 0);

  HybridLogicalClock getHlc(int ms, int counter, int site) {
    return HybridLogicalClock(ms, counter);
  }

  HybridLogicalClock getForSend() {
    _localTime = HybridLogicalClock.send(_localTime);
    return _localTime;
  }

  void fromReceive(HybridLogicalClock incoming) {
    _localTime = HybridLogicalClock.recv(_localTime, incoming);
  }

  // ts key in  minutes to logical!
  /// TODO: Refactor, where its actually made!
  int tsKeyToMillisecond(String tsKey) {
    return (int.parse(tsKey, radix: 36) * 60000);
  }

  HybridLogicalClock getClockFromTSKey(String tsKey, int site) {
    final ms = tsKeyToMillisecond(tsKey);
    return getHlc(ms, 0, site);
  }
}
