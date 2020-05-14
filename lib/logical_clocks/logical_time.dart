import 'package:sync_layer/basic/index.dart';
import 'logial_clock.dart';

/// somewhat close to lamport clock
/// moor like a version vector
class LogicalTime implements LogicalClock<LogicalTime> {
  @override

  /// to be compatible to js, only 32 bits!
  final int counter;

  @override
  final int site;

  final String _logicalClock;
  int _hashCode;

  LogicalTime(this.counter, this.site)
      : _logicalClock = '${counter.toRadixString(16)}-${site.toRadixString(16)}',
        assert(counter != null),
        assert(site != null) {
    _hashCode = MurmurHashV3(_logicalClock);
  }

  @override
  String radixTime(int radix) {
    throw AssertionError('Radix Time is not supported yet');
  }

  factory LogicalTime.send(LogicalClock lc) {
    return LogicalTime(lc.counter + 1, lc.site);
  }

  factory LogicalTime.recv(LogicalClock lc) {
    throw AssertionError('recv is not supported yet');
  }

  @override
  factory LogicalTime.parse(String ts) {
    final parts = ts.split('-');
    assert(parts.length == 2, 'Time format does not match');

    var counter = int.parse(parts[0], radix: 16);
    var site = int.parse(parts[1], radix: 16);

    return LogicalTime(counter, site);
  }

  @override
  int compareTo(LogicalTime other) => counter.compareTo(other.counter);

  ///
  /// meaning : left is older than right
  /// returns [true] if left < right
  /// This function also compares the node lexographically if node of l < node of r
  /// Todo: think about, what if the hlc are identical
  static bool compareWithNodes(LogicalTime left, LogicalTime right) {
    /// first by timestamp
    if (left < right) return true;
    if (left == right) return left.site < right.site;
    return false;
  }

  @override
  int get hashCode => _hashCode;

  @override
  bool operator ==(other) => other is LogicalTime && counter == other.counter && site == other.site;

  ///
  /// meaning : left is older than right
  /// returns [true] if left < right
  /// This function also compares the node lexographically if node of l < node of r
  @override
  bool operator <(other) {
    final o = other as LogicalTime;

    if (counter < o.counter) {
      return true;
    } else if (counter == o.counter) return site < o.site;

    return false;
  }

  @override
  bool operator >(other) {
    final o = other as LogicalTime;

    if (counter > o.counter) {
      return true;
    } else if (counter == o.counter) return site > o.site;

    return false;
  }

  @override
  List<int> operator -(other) {
    final o = other as LogicalTime;
    return [counter - o.counter];
  }

  /// added List<int> as difference to the counter !!
  // @override
  // void operator +(other) {
  //   final o = other as List<int>;
  //   assert(o.length != 1, 'adding only a list of int of length 1');
  //   counter += o[0];
  // }

  @override
  String toString() => _logicalClock;

  @override
  String toStringRON() => 'S${site.toRadixString(16)}@T${counter.toRadixString(16)}';

  @override
  String toStringHuman() => toStringRON();
}
