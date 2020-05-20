import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/index.dart';

void main() {
  encodeCausalEntry();
}

void encodeCausalEntry() {
  final id = Id(LogicalClock(1), 20);
  final cause = Id(LogicalClock(0), 20);
  final entry = CausalEntry(id, cause: cause, data: null);

  final bytes = msgpackEncode(entry);
  final entryCopy = msgpackDecode(bytes);
  print(entry);
  print(bytes);
  print(bytes.length);
  print(entryCopy);
}
