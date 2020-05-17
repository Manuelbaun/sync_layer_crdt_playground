import 'package:sync_layer/types/id_atom.dart';
import 'package:sync_layer/types/index.dart';

void main() {
  final aid = AtomId(HybridLogicalClock(20, 0), 10);
  print(aid);
  print(aid.toString());
}
