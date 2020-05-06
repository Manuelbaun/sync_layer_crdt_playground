///
//  Generated code. Do not modify.
//  source: atom.proto
//
// @dart = 2.3
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name,return_of_invalid_type

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

enum AtomBin_Values {
  n, 
  n64, 
  s, 
  notSet
}

class AtomBin extends $pb.GeneratedMessage {
  static const $core.Map<$core.int, AtomBin_Values> _AtomBin_ValuesByTag = {
    6 : AtomBin_Values.n,
    7 : AtomBin_Values.n64,
    8 : AtomBin_Values.s,
    0 : AtomBin_Values.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('AtomBin', createEmptyInstance: create)
    ..oo(0, [6, 7, 8])
    ..aInt64(1, 'ts')
    ..a<$core.int>(2, 'node', $pb.PbFieldType.O3)
    ..aOS(3, 'id')
    ..a<$core.int>(4, 'type', $pb.PbFieldType.O3)
    ..a<$core.int>(5, 'key', $pb.PbFieldType.O3)
    ..a<$core.int>(6, 'n', $pb.PbFieldType.O3)
    ..aInt64(7, 'n64')
    ..aOS(8, 's')
    ..hasRequiredFields = false
  ;

  AtomBin._() : super();
  factory AtomBin() => create();
  factory AtomBin.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AtomBin.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);
  AtomBin clone() => AtomBin()..mergeFromMessage(this);
  AtomBin copyWith(void Function(AtomBin) updates) => super.copyWith((message) => updates(message as AtomBin));
  $pb.BuilderInfo get info_ => _i;
  @$core.pragma('dart2js:noInline')
  static AtomBin create() => AtomBin._();
  AtomBin createEmptyInstance() => create();
  static $pb.PbList<AtomBin> createRepeated() => $pb.PbList<AtomBin>();
  @$core.pragma('dart2js:noInline')
  static AtomBin getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AtomBin>(create);
  static AtomBin _defaultInstance;

  AtomBin_Values whichValues() => _AtomBin_ValuesByTag[$_whichOneof(0)];
  void clearValues() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get ts => $_getI64(0);
  @$pb.TagNumber(1)
  set ts($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTs() => $_has(0);
  @$pb.TagNumber(1)
  void clearTs() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get node => $_getIZ(1);
  @$pb.TagNumber(2)
  set node($core.int v) { $_setSignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNode() => $_has(1);
  @$pb.TagNumber(2)
  void clearNode() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get type => $_getIZ(3);
  @$pb.TagNumber(4)
  set type($core.int v) { $_setSignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasType() => $_has(3);
  @$pb.TagNumber(4)
  void clearType() => clearField(4);

  @$pb.TagNumber(5)
  $core.int get key => $_getIZ(4);
  @$pb.TagNumber(5)
  set key($core.int v) { $_setSignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasKey() => $_has(4);
  @$pb.TagNumber(5)
  void clearKey() => clearField(5);

  @$pb.TagNumber(6)
  $core.int get n => $_getIZ(5);
  @$pb.TagNumber(6)
  set n($core.int v) { $_setSignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasN() => $_has(5);
  @$pb.TagNumber(6)
  void clearN() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get n64 => $_getI64(6);
  @$pb.TagNumber(7)
  set n64($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasN64() => $_has(6);
  @$pb.TagNumber(7)
  void clearN64() => clearField(7);

  @$pb.TagNumber(8)
  $core.String get s => $_getSZ(7);
  @$pb.TagNumber(8)
  set s($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasS() => $_has(7);
  @$pb.TagNumber(8)
  void clearS() => clearField(8);
}

