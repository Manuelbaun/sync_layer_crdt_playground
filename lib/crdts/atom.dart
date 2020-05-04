import 'package:sync_layer/basic/hlc.dart';

class Atom<T> {
  final Hlc id;
  T value;

  Atom({this.id, this.value});

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;
    return o is Atom && o.id == id && o.value == value;
  }

  @override
  int get hashCode => id.hashCode ^ value.hashCode;

  @override
  String toString() => '$id:$value';

  /// Returns the Atom with the "higher" ID
  static Atom max(Atom a, Atom b) {
    return Id.greater(a.id, b.id) ? a : b;
  }
}
