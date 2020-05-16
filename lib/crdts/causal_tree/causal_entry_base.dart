import 'package:sync_layer/types/abstract/id_base.dart';
import 'package:sync_layer/types/abstract/logical_clock_base.dart';

enum RelationShip { Sibling, CausalLeft, CausalRight, Unknown, Identical }

abstract class CausalEntryBase<T> {
  CausalEntryBase(this.id, {this.data, this.cause});
  final IdBase id;
  final IdBase cause;
  final T data;

  LogicalClockBase get ts;
  int get site;

  LogicalClockBase get causeTs;
  int get causeSite;

  RelationShip relatesTo(CausalEntryBase other);
  bool isSibling(CausalEntryBase other);
  bool isLeftOf(CausalEntryBase other);

  @override
  operator ==(other);
}
