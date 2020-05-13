import 'package:sync_layer/logical_clocks/index.dart';

abstract class AtomBase<T> {
  final LogicalClock clock;
  final T data;
  AtomBase(this.clock, this.data);
}
