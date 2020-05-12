import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;

import 'package:sync_layer/logger/index.dart';

import 'dao.dart';
import 'package:sync_layer/index.dart';

void main() async {
  final server = await HttpServer.bind('0.0.0.0', 8000);

  logger.fine('listen to 0.0.0.0:8000');

  final syn = SyncLayerImpl(0);
  final daoTodo = syn.registerObjectType<Todo>('todos', (c, id) => Todo(c, id: id));
  final daoAss = syn.registerObjectType<Assignee>('assignee', (c, id) => Assignee(c, id: id));

  daoTodo.changeStream.listen((objs) {
    objs.forEach((e) => logger.fine(e.toString()));
  });

  daoAss.changeStream.listen((objs) => objs.forEach((o) => logger.fine(o.toString())));

  final protocol = SyncLayerProtocol(syn);

  server.listen((HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket ws) {
      protocol.registerConnection(ws);
    }, onError: (err) => logger.error('[!]Error -- ${err.toString()}'));
  }, onError: (err) => logger.error('[!]Error -- ${err.toString()}'));
}
