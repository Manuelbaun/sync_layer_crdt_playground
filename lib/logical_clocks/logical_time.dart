import 'package:sync_layer/basic/index.dart';
import 'package:sync_layer/logical_clocks/index.dart';
import 'logial_clock.dart';

/// Importent!!!
/// when compare two logical clocks,
/// it only compares the time aspects of it! it does not consider the site aspects
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
        assert(counter != null && counter >= 0),
        assert(site != null && site != null) {
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

  /// * Hlc(30, ...).compareTo(Hlc(20, ..)) => 1
  /// * Hlc(30, some counter).compareTo(Hlc(30, same counter)) => 0
  /// * Hlc(20, ...).compareTo(Hlc(30, ..)) => -1
  @override
  int compareTo(LogicalTime other) => counter.compareTo(other.counter);

  @override
  int compareToDESC(LogicalTime other) => compareTo(other) * -1;

  @override
  int compareWithSiteASC(LogicalTime other) {
    final res = counter.compareTo(other.counter);
    if (res == 0) {
      return site.compareTo(other.site);
    }
    return res;
  }

  @override
  int compareWithSiteDESC(LogicalTime other) => compareWithSiteASC(other) * -1;

  /// is the unique hash of the logical time,
  /// it consists of counter and site as radix 16
  /// hashed with MurmurHashV3
  @override
  int get hashCode => _hashCode;

  /// Id same as [hashCode], just for better reasoning
  @override
  int get id => _hashCode;

  /// compares only counter/time!! not site!!
  @override
  bool operator ==(other) => other is LogicalTime && counter == other.counter;

  ///
  /// compares the time if less/smaller counter => its older!
  @override
  bool operator <(o) => o is LogicalTime && counter < o.counter;

  /// compares the time if greater/bigger counter => its newer!
  @override
  bool operator >(o) => o is LogicalTime && counter > o.counter;

  /// calculates only the diffes of the [counter]
  @override
  List<int> operator -(other) {
    final o = other as LogicalTime;
    return [counter - o.counter];
  }

  @override
  String toString() => _logicalClock;

  @override
  String toStringRON() => 'S${site.toRadixString(16)}@T${counter.toRadixString(16)}';

  @override
  String toStringHuman() => toStringRON();
}
