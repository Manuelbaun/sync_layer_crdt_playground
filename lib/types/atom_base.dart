import 'package:sync_layer/logical_clocks/index.dart';

abstract class AtomBase<T> {
  /// depending on the atom type, the id the hashcode of the atom or the clock
  int get id;
  final LogicalClock clock;
  final T data;
  AtomBase(this.clock, this.data);
}
