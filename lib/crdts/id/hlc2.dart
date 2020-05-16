import 'dart:math';
import 'logical_clock_base.dart';

const _COUNTER_MASK = 0xFFFF;
const _MAX_COUNTER = _COUNTER_MASK;
const _MAX_DRIFT = 60000;
const RESOLUTION = 60000;

// https://github.com/cachapa/crdt

// see Slides here: https://jlongster.com/s/dotjs-crdt-slides.pdf
// View this app here: https://crdt.jlongster.com

/// Importent: The Hlc compares onle milliseconds and counter not site!

/// A Hybrid Logical Clock implementation.
/// This class trades time precision for a guaranteed monotonically increasing
/// clock in distributed systems.
/// Inspiration: https://cse.buffalo.edu/tech-reports/2014-04.pdf
///
/// It consist of 64 bits, where the top 48 bit represent the time in milliseconds
/// and the lower 16 bits are counter values, as logical time
///

/// This Hlc implementation does not have the 64 bit represention as a logical clock, it always uses milliseconds - counter - site.
/// This is due the fact, that javascript does not support xor manipulation on 64 bits
/// it always converts it to 32 bits. So a 64 bit logical time, when used with bit shift, will lose the upper 32 bits!
///

class Hlc implements LogicalClockBase<Hlc> {
  @override
  final int logicalTime;

  final int ms;
  final int counter;
  final int minutes;

  Hlc([int ms_, this.counter = 0])
      : assert(counter < _MAX_COUNTER && counter >= 0),
        ms = ms_ ??= DateTime.now().millisecondsSinceEpoch,
        assert(ms_ >= 0),
        logicalTime = ms_ << 16 | counter & 0xffff,
        minutes = (ms_ / RESOLUTION).floor();

  /// Convert the [minutes] to radix
  @override
  String radixTime(int radix) => minutes.toRadixString(radix);

  // remove node complety
  factory Hlc.parse(String timestamp) {
    // throw AssertionError('not ready to parse ...');
    final parts = timestamp.split('-');
    assert(parts.length == 2, 'Time format does not match');

    var ms = int.parse(parts[0], radix: 16);
    var counter = int.parse(parts[1], radix: 16);

    return Hlc(ms, counter);
  }

  /// Generates a unique, monotonic timestamp suitable for transmission to
  /// another system in string format. Local wall time will be used if [milliseconds]
  /// isn't supplied, useful for testing.
  factory Hlc.send(Hlc clock, [int ms]) {
    // Retrieve the local wall time if micros is null
    ms = (ms ?? DateTime.now().millisecondsSinceEpoch);

    // Unpack the timestamp's time and counter
    var msOld = clock.ms;
    var counterOld = clock.counter;

    // Calculate the next logical time and counter
    // * ensure that the logical time never goes backward
    // * increment the counter if physical time does not advance
    var msNew = max(msOld, ms);
    var counterNew = msOld == msNew ? counterOld + 1 : 0;

    // Check the result for drift and counter overflow
    if (msNew - ms > _MAX_DRIFT) {
      throw ClockDriftException(msNew, ms);
    }
    if (counterNew > _MAX_COUNTER) {
      throw OverflowException(counterNew);
    }

    return Hlc(msNew, counterNew);
  }

  @override
  factory Hlc.fromLogical(int ts) => Hlc(ts >> 16, ts & 0xffff);

  /// Parses and merges a timestamp from a remote system with the local
  /// canonical timestamp to preserve monotonicity. Returns an updated canonical
  /// timestamp instance. Local wall time will be used if [ms] isn't
  /// supplied, useful for testing.
  factory Hlc.recv(Hlc local, Hlc remote, [int ms]) {
    // Retrieve the local wall time if micros is null
    ms = (ms ?? DateTime.now().millisecondsSinceEpoch);

    // Unpack the remote's time and counter
    var msRemote = remote.ms;
    var counterRemote = remote.counter;

    // Assert remote clock drift
    if (msRemote - ms > _MAX_DRIFT) {
      throw ClockDriftException(msRemote, ms);
    }

    // Unpack the clock.timestamp logical time and counter
    var msLocal = local.ms;
    var counterLocal = local.counter;

    // Calculate the next logical time and counter.
    // Ensure that the logical time never goes backward;
    // * if all logical clocks are equal, increment the max counter,
    // * if max = old > message, increment local counter,
    // * if max = message > old, increment message counter,
    // * otherwise, clocks are monotonic, reset counter
    var msNew = max(max(msLocal, ms), msRemote);
    var counterNew = msNew == msLocal && msNew == msRemote
        ? max(counterLocal, counterRemote) + 1
        : msNew == msLocal ? counterLocal + 1 : msNew == msRemote ? counterRemote + 1 : 0;

    // Check the result for drift and counter overflow
    if (msNew - ms > _MAX_DRIFT) {
      throw ClockDriftException(msNew, ms);
    }
    if (counterNew > _MAX_COUNTER) {
      throw OverflowException(counterNew);
    }

    return Hlc(msNew, counterNew);
  }

  /// use hashcode  if compare to another HLC to check if they are really equal!
  /// this uses the murmurhashv3 and hashes [milliseconds], [counter] and [site]
  @override
  int get hashCode => _hashCode;
  int _hashCode;

  // @override
  // bool operator ==(other) => other is Hlc && ms == other.ms && counter == other.counter;
  // @override
  // bool operator <(o) => o is Hlc && (ms == o.ms ? counter < o.counter : ms < o.ms);
  // @override
  // bool operator <=(o) => o is Hlc && (ms == o.ms ? counter <= o.counter : ms <= o.ms);
  // @override
  // bool operator >(o) => o is Hlc && (ms == o.ms ? counter > o.counter : ms > o.ms);
  // @override
  // bool operator >=(o) => o is Hlc && (ms == o.ms ? counter >= o.counter : ms >= o.ms);

  @override
  bool operator ==(other) => other is Hlc && logicalTime == other.logicalTime;
  @override
  bool operator <(o) => o is Hlc && logicalTime < o.logicalTime;
  @override
  bool operator <=(o) => o is Hlc && logicalTime < o.logicalTime;
  @override
  bool operator >(o) => o is Hlc && logicalTime > o.logicalTime;
  @override
  bool operator >=(o) => o is Hlc && logicalTime >= o.logicalTime;

  /// calculates the diffes of the [logicaltime] difference
  @override
  int operator -(other) {
    final o = other as Hlc;
    return logicalTime - o.logicalTime;
  }

  String toStringNice() =>
      '${DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)}-${counter.toRadixString(16).padLeft(4, '0')}';

  @override
  String toString() => '${ms.toRadixString(16)}-${counter.toRadixString(16)}';

  @override
  int compareTo(Hlc other) {
    final res = ms.compareTo(other.ms);
    if (res == 0) return counter.compareTo(other.counter);
    return res;
  }
}

class ClockDriftException implements Exception {
  final int drift;

  ClockDriftException(int msTs, int msWall) : drift = msTs - msWall;

  @override
  String toString() => 'Clock drift of $drift ms exceeds maximum ($_MAX_DRIFT).';
}

class OverflowException implements Exception {
  final int counter;

  OverflowException(this.counter);

  @override
  String toString() => 'Timestamp counter overflow: $counter.';
}
