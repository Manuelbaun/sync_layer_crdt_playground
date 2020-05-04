// https://github.com/cachapa/crdt

import 'dart:math';
import 'dart:typed_data';

import 'murmur_hash.dart';

const _COUNTER_MASK = 0xFFFF;
const _MAX_COUNTER = _COUNTER_MASK;
const _MAX_DRIFT = 60000; // TODO: read paper about the drift

const RESOLUTION = 60000;

// see Slides here: https://jlongster.com/s/dotjs-crdt-slides.pdf
// View this app here: https://crdt.jlongster.com

/// A Hybrid Logical Clock implementation.
/// This class trades time precision for a guaranteed monotonically increasing
/// clock in distributed systems.
/// Inspiration: https://cse.buffalo.edu/tech-reports/2014-04.pdf
///
/// It consist of 64 bits, where the top 48 bit represent the time in milliseconds
/// and the lower 16 bits are counter values, as logical time
///
/// TODO: Overwork this Hlc remove what is not needed
class Hlc implements Comparable<Hlc> {
  int _millis;
  int _counter;
  int _minutes;

  int _logicalTime;

  // int has radix
  String toRadixString(int radix) => _minutes.toRadixString(radix);

  int get millis => _millis;
  int get counter => _counter;
  int get minutes => _minutes;
  int get logicalTime => _logicalTime;

  DateTime _time4debug;
  DateTime get time4debug => _time4debug;

  final String node;

  Hlc([int millis, int counter = 0, this.node = '0']) : assert(counter < _MAX_COUNTER) {
    _millis = (millis ?? DateTime.now().millisecondsSinceEpoch);

    // only for debug, remove later!
    _time4debug = DateTime.fromMillisecondsSinceEpoch(_millis);

    _counter = counter;
    _minutes = (_millis / RESOLUTION).floor();

    _logicalTime = (_millis << 16) | counter;
  }

  factory Hlc.fromLogicalTime(int logicalTime, [String nodeId]) {
    final millis = logicalTime >> 16;
    final counter = logicalTime & 0xFFFF;
    return Hlc(millis, counter, nodeId);
  }

  // remove node complety
  factory Hlc.parse(String timestamp) {
    final parts = timestamp.split('-');
    assert(parts.length == 5, 'Time format does not match, missing ');

    final dateobj = parts.sublist(0, 3).join('-');
    var millis = DateTime.parse(dateobj).millisecondsSinceEpoch;
    var counter = int.parse(parts[3], radix: 16);
    var node = parts[4];

    return Hlc(millis, counter, node);
  }

  /// Generates a unique, monotonic timestamp suitable for transmission to
  /// another system in string format. Local wall time will be used if [milliseconds]
  /// isn't supplied, useful for testing.
  factory Hlc.send(Hlc timestamp, [int millis]) {
    // Retrieve the local wall time if micros is null
    millis = (millis ?? DateTime.now().millisecondsSinceEpoch);

    // Unpack the timestamp's time and counter
    var millisOld = timestamp.millis;
    var counterOld = timestamp.counter;

    // Calculate the next logical time and counter
    // * ensure that the logical time never goes backward
    // * increment the counter if physical time does not advance
    var millisNew = max(millisOld, millis);
    var counterNew = millisOld == millisNew ? counterOld + 1 : 0;

    // Check the result for drift and counter overflow
    if (millisNew - millis > _MAX_DRIFT) {
      throw ClockDriftException(millisNew, millis);
    }
    if (counterNew > _MAX_COUNTER) {
      throw OverflowException(counterNew);
    }

    return Hlc(millisNew, counterNew, timestamp.node);
  }

  /// Parses and merges a timestamp from a remote system with the local
  /// canonical timestamp to preserve monotonicity. Returns an updated canonical
  /// timestamp instance. Local wall time will be used if [millis] isn't
  /// supplied, useful for testing.
  factory Hlc.recv(Hlc local, Hlc remote, [int millis]) {
    // Retrieve the local wall time if micros is null
    millis = (millis ?? DateTime.now().millisecondsSinceEpoch);

    // Unpack the remote's time and counter
    var millisRemote = remote.millis;
    var counterRemote = remote.counter;

    // Assert remote clock drift
    if (millisRemote - millis > _MAX_DRIFT) {
      throw ClockDriftException(millisRemote, millis);
    }

    // Unpack the clock.timestamp logical time and counter
    var millisLocal = local.millis;
    var counterLocal = local.counter;

    // Calculate the next logical time and counter.
    // Ensure that the logical time never goes backward;
    // * if all logical clocks are equal, increment the max counter,
    // * if max = old > message, increment local counter,
    // * if max = message > old, increment message counter,
    // * otherwise, clocks are monotonic, reset counter
    var millisNew = max(max(millisLocal, millis), millisRemote);
    var counterNew = millisNew == millisLocal && millisNew == millisRemote
        ? max(counterLocal, counterRemote) + 1
        : millisNew == millisLocal ? counterLocal + 1 : millisNew == millisRemote ? counterRemote + 1 : 0;

    // Check the result for drift and counter overflow
    if (millisNew - millis > _MAX_DRIFT) {
      throw ClockDriftException(millisNew, millis);
    }
    if (counterNew > _MAX_COUNTER) {
      throw OverflowException(counterNew);
    }

    return Hlc(millisNew, counterNew, local.node);
  }

  String toJson() => toString();

  @override
  String toString() => '${DateTime.fromMillisecondsSinceEpoch(_millis, isUtc: true).toIso8601String()}'
      '-'
      '${counter.toRadixString(16).toUpperCase().padLeft(4, '0')}'
      '-$node';

  String toString2() => '${millis}-${counter.toRadixString(16)}-$node';
  String toString3() => '${logicalTime}-$node';
  String toString4() => '${logicalTime.toRadixString(36)}-$node';

  @override
  int get hashCode => MurmurHashV3(toString());
  int get hashCode2 => MurmurHashV3(toString2());
  int get hashCode3 => MurmurHashV3(toString3());
  int get hashCode4 => MurmurHashV3(toString4());

  @override
  bool operator ==(other) => other is Hlc && logicalTime == other.logicalTime;

  bool operator <(other) => other is Hlc && logicalTime < other.logicalTime;

  bool operator <=(other) => other is Hlc && logicalTime <= other.logicalTime;

  bool operator >(other) => other is Hlc && logicalTime > other.logicalTime;

  bool operator >=(other) => other is Hlc && logicalTime >= other.logicalTime;

  @override
  int compareTo(Hlc other) => logicalTime.compareTo(other.logicalTime);
}

class ClockDriftException implements Exception {
  final int drift;

  ClockDriftException(int millisTs, int millisWall) : drift = millisTs - millisWall;

  @override
  String toString() => 'Clock drift of $drift ms exceeds maximum ($_MAX_DRIFT).';
}

class OverflowException implements Exception {
  final int counter;

  OverflowException(this.counter);

  @override
  String toString() => 'Timestamp counter overflow: $counter.';
}
