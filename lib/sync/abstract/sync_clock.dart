import 'package:sync_layer/types/abstract/logical_clock_base.dart';

abstract class SyncLayerClock {
  SyncLayerClock(LogicalClockBase initalClock);

  LogicalClockBase get localTime;

  // this is a factory function to convert logical time to LogicalClockBase
  LogicalClockBase getClock(int logicalTime);

  /// from incoming Site
  void applyReceivedClock(LogicalClockBase incoming);

  /// created a new Logical clock, for all sorts of application
  LogicalClockBase getNextTs();

  /// Convert functions => rethink!
  // ts key in  minutes to logical!
  /// TODO: Refactor, where its actually made!
  int convertRadix(String tsKey);

  LogicalClockBase getClockFromTSKey(String tsKey, int site);
}
