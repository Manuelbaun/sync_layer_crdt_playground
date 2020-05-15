import 'dart:math';
import 'package:sync_layer/basic/murmur_hash.dart';
import 'logial_clock.dart';

const _COUNTER_MASK = 0xFFFF;
const _MAX_COUNTER = _COUNTER_MASK;
const _MAX_DRIFT = 60000;
const RESOLUTION = 60000;

// https://github.com/cachapa/crdt

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

/// This Hlc implementation does not have the 64 bit represention as a logical clock, it always uses milliseconds - counter - site.
/// This is due the fact, that javascript does not support xor manipulation on 64 bits
/// it always converts it to 32 bits. So a 64 bit logical time, when used with bit shift, will lose the upper 32 bits!
class Hlc implements LogicalClock<Hlc> {
  final int ms;

  @override
  final int counter;

  @override
  final int site;
  int _minutes;
  int get minutes => _minutes;

  @override
  int get hashCode => _hashCode;
  int _hashCode;

  String _internal;

  Hlc([int ms_, this.counter = 0, this.site])
      : assert(counter < _MAX_COUNTER && counter >= 0),
        assert(site != null && site >= 0),
        ms = ms_ ??= DateTime.now().millisecondsSinceEpoch,
        assert(ms_ >= 0) {
    // TODO: maybe add padding before release, after that, no changes to the hash function!
    _internal = '${ms.toRadixString(16)}-${counter.toRadixString(16)}-${site.toRadixString(16)}';
    _hashCode = MurmurHashV3(_internal);
    _minutes = (ms / RESOLUTION).floor();
  }

  /// Convert the [minutes] to radix
  @override
  String radixTime(int radix) => minutes.toRadixString(radix);

  // remove node complety
  factory Hlc.parse(String timestamp) {
    final parts = timestamp.split('-');
    assert(parts.length == 3, 'Time format does not match');

    var ms = int.parse(parts[0], radix: 16);
    var counter = int.parse(parts[1], radix: 16);
    var site = int.parse(parts[2], radix: 16);

    return Hlc(ms, counter, site);
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

    return Hlc(msNew, counterNew, clock.site);
  }

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

    return Hlc(msNew, counterNew, local.site);
  }

  @override
  bool operator ==(other) => other is Hlc && ms == other.ms && counter == other.counter && site == other.site;

  ///
  /// meaning : left is older than right
  /// returns [true] if left < right
  /// This function also compares the node lexographically if node of l < node of r
  @override
  bool operator <(other) {
    final o = other as Hlc;

    if (ms < o.ms) {
      return true;
    } else if (ms == o.ms) {
      if (counter < o.counter) {
        return true;
      } else if (counter == o.counter) return site < o.site;
    }

    return false;
  }

  @override
  bool operator >(other) {
    final o = other as Hlc;

    if (ms > o.ms) {
      return true;
    } else if (ms == o.ms) {
      if (counter > o.counter) {
        return true;
      } else if (counter == o.counter) return site > o.site;
    }

    return false;
  }

  @override
  List<int> operator -(other) {
    final o = other as Hlc;
    return [ms - o.ms, counter - o.counter];
  }

  @override
  String toString() => _internal;

  @override
  String toStringHuman() => '${DateTime.fromMillisecondsSinceEpoch(ms).toIso8601String()}-${counter}-${site}';

  @override
  String toStringRON() => 'S${site.toRadixString(16)}@T${ms.toRadixString(16)}-${counter.toRadixString(16)}';

  @override

// 1.compareTo(2) => -1
// 2.compareTo(1) => 1
// 1.compareTo(1) => 0
  int compareTo(Hlc other) {
    final res = ms.compareTo(other.ms);

    if (res == 0) {
      final cRes = counter.compareTo(other.counter);

      if (cRes == 0) return site.compareTo(other.site);
      return cRes;
    }
    return res;
  }

  @override
  int compareToDESC(Hlc other) {
    final res = ms.compareTo(other.ms);

    if (res == 0) {
      final cRes = counter.compareTo(other.counter);

      if (cRes == 0) return site.compareTo(other.site) * -1;
      return cRes * -1;
    }

    return res * -1;
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
