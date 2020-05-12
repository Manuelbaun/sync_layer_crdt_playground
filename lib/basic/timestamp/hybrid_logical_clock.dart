// https://github.com/cachapa/crdt

import 'dart:math';
import 'dart:typed_data';
import 'package:sync_layer/encoding_extent/encode_decode_int.dart';

import '../murmur_hash.dart';

const _COUNTER_MASK = 0xFFFF;
const _MAX_COUNTER = _COUNTER_MASK;
const _MAX_DRIFT = 60000;
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

class Hlc implements Comparable<Hlc> {
  final int millis;
  final int counter;
  final int minutes;

  final int logicalTime;
  final int site;

  String _internal;
  int _hashcode;

  // call only if needed!
  Uint8List toBytes() {
    final m = encodeTrimmedInt(logicalTime); // max 6 bytes
    final s = encodeTrimmedInt(site); // max 4 bytes

    var full = Uint8List.fromList([m.length, ...m, ...s]);
    return full;
  }

  factory Hlc.fromBytes(Uint8List buff) {
    final ml = buff[0];
    final data = buff.sublist(1);

    final m = decodeTrimmedInt(data.sublist(0, ml), 8);
    final s = decodeTrimmedInt(data.sublist(ml));

    return Hlc.fromLogicalTime(m, s);
  }

  Hlc(int ms, this.counter, this.site)
      : assert(counter < _MAX_COUNTER),
        assert(site != null),
        millis = (ms ?? DateTime.now().millisecondsSinceEpoch),
        minutes = (ms / RESOLUTION).floor(),
        logicalTime = (ms << 16) | counter {
    _internal = '${logicalTime.toRadixString(16)}-${site.toRadixString(16)}';
    _hashcode = MurmurHashV3(_internal);
  }

  /// Convert the [minutes] to radix
  String radixTime(int radix) => minutes.toRadixString(radix);

  factory Hlc.fromLogicalTime(int logicalTime, int site) {
    final millis = logicalTime >> 16;
    final counter = logicalTime & 0xFFFF;
    return Hlc(millis, counter, site);
  }

  // remove node complety
  factory Hlc.parse(String timestamp) {
    final parts = timestamp.split('-');
    assert(parts.length == 2, 'Time format does not match');

    var logicalTime = int.parse(parts[0], radix: 16);
    var site = int.parse(parts[1], radix: 16);

    return Hlc.fromLogicalTime(logicalTime, site);
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

    return Hlc(millisNew, counterNew, timestamp.site);
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

    return Hlc(millisNew, counterNew, local.site);
  }

  @override
  String toString() => _internal;

  @override
  int get hashCode => _hashcode;

  @override
  bool operator ==(other) => other is Hlc && logicalTime == other.logicalTime;

  bool operator <(other) => other is Hlc && logicalTime < other.logicalTime;

  bool operator <=(other) => other is Hlc && logicalTime <= other.logicalTime;

  bool operator >(other) => other is Hlc && logicalTime > other.logicalTime;

  bool operator >=(other) => other is Hlc && logicalTime >= other.logicalTime;

  @override
  int compareTo(Hlc other) => logicalTime.compareTo(other.logicalTime);

  /// checks logical time and site id!
  static bool isEqual(Hlc left, Hlc right) {
    return left?.logicalTime == right?.logicalTime && left?.site == right?.site;
  }

  ///
  /// meaning : left is older than right
  /// returns [true] if left < right
  /// This function also compares the node lexographically if node of l < node of r
  /// Todo: think about, what if the hlc are identical
  static bool compareWithNodes(Hlc left, Hlc right) {
    /// first by timestamp
    if (left < right) return true;
    if (left == right) return left.site < right.site;
    return false;
  }
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
