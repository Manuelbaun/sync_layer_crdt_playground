import 'id.dart';
import 'lc2.dart';

enum RelationShip { Sibling, CausalLeft, CausalRight, Unknown, Identical }

abstract class CausalEntryBase<T> {
  CausalEntryBase(this.id, {this.data, this.cause});
  final Id id;
  final Id cause;
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
