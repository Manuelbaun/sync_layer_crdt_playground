import 'package:sync_layer/crdts/causal_tree/causal_entry.dart';
import 'package:sync_layer/encoding_extent/index.dart';
import 'package:sync_layer/types/id.dart';
import 'package:sync_layer/types/index.dart';

void main() {
  encodeCausalEntry();
  encodeCausalEntryWithAtom();
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
  print('----------------');
}

void encodeCausalEntryWithAtom() {
  final id = Id(LogicalClock(1), 20);
  final cause = Id(LogicalClock(0), 20);

  final entry = CausalEntry(id, cause: cause, data: null);
  final ts = HybridLogicalClock(DateTime(2020).millisecondsSinceEpoch, 0);

  final atomId = Id(ts, 20);
  final atom = Atom(atomId, 1, 'uuid', entry);

  final bytes = msgpackEncode(atom);
  final atomCopy = msgpackDecode(bytes);
  print(entry);
  print(bytes);
  print(bytes.length);
  print(atomCopy);
  print('----------------');
}
