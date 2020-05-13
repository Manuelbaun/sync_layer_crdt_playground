import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';

import 'ext_decoder.dart';
import 'ext_encoder.dart';

final _valueEncoder = ExtendetEncoder();
final _valueDecoder = ExtendetDecoder();

Uint8List msgpackEncode(dynamic v) => serialize(v, extEncoder: _valueEncoder);
dynamic msgpackDecode(dynamic v) => deserialize(v, extDecoder: _valueDecoder);
