import 'package:sync_layer/types/index.dart';

void main() {
  final aid = Id(HybridLogicalClock(20, 0), 10);
  print(aid);
  print(aid.toString());
}
