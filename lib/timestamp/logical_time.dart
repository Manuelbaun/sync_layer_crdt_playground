import 'package:sync_layer/basic/index.dart';

import 'logial_clock.dart';

/// somewhat close to lamport clock
/// mehr like a version vector
class LogicalTime implements LogicalClock, Comparable<LogicalClock> {
  @override
  final int logicalTime;

  @override
  final int site;

  String _internal;
  int _hashCode;
  LogicalTime(this.logicalTime, this.site) {
    _internal = '$logicalTime-$site';
    _hashCode = MurmurHashV3(_internal);
  }

  @override
  String radixTime(int radix) {
    throw AssertionError('Radix Time is not supported yet');
  }

  factory LogicalTime.send(LogicalClock lc) {
    return LogicalTime(lc.logicalTime + 1, lc.site);
  }

  factory LogicalTime.recv(LogicalClock lc) {
    throw AssertionError('recv is not supported yet');
  }

  @override
  factory LogicalTime.parse(String ts) {
    final parts = ts.split('-');
    assert(parts.length == 2, 'Time format does not match');

    var logicalTime = int.parse(parts[0], radix: 16);
    var site = int.parse(parts[1], radix: 16);

    return LogicalTime.fromLogicalTime(logicalTime, site);
  }

  @override
  factory LogicalTime.fromLogicalTime(int logicalTime, int site) {
    return LogicalTime(logicalTime, site);
  }

  @override
  int compareTo(LogicalClock other) => logicalTime.compareTo(other.logicalTime);

  ///
  /// meaning : left is older than right
  /// returns [true] if left < right
  /// This function also compares the node lexographically if node of l < node of r
  /// Todo: think about, what if the hlc are identical
  static bool compareWithNodes(LogicalClock left, LogicalClock right) {
    /// first by timestamp
    if (left < right) return true;
    if (left == right) return left.site < right.site;
    return false;
  }

  @override
  int get hashCode => _hashCode;

  @override
  bool operator ==(other) => other is LogicalClock && logicalTime == other.logicalTime && site == other.site;

  @override
  bool operator <(other) {
    final o = other as LogicalClock;

    if (logicalTime < o.logicalTime) {
      return true;
    } else if (logicalTime == o.logicalTime) return site < o.site;

    return false;
  }

  @override
  bool operator >(other) {
    final o = other as LogicalClock;

    if (logicalTime > o.logicalTime) {
      return true;
    } else if (logicalTime == o.logicalTime) return site > o.site;

    return false;
  }

  @override
  String toString() => _internal;

  @override
  String toRON() => 'S$site@T$logicalTime';
}
