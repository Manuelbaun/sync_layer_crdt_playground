class SyncLayerError extends Error {
  final String msg;
  SyncLayerError(this.msg) : super();
  @override
  String toString() => 'SyncLayerError($msg)';
}
