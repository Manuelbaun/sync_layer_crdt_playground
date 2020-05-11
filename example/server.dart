import 'dart:io' show HttpServer, HttpRequest, WebSocket, WebSocketTransformer;

import 'dao.dart';
import 'package:sync_layer/index.dart';

void main() async {
  final server = await HttpServer.bind('0.0.0.0', 8000);

  print('listen to 0.0.0.0:8000');

  final syn = SyncLayerImpl('server');
  final daoTodo = syn.registerObjectType<Todo2>('todos', (c, id) => Todo2(c, id: id));
  final daoAss = syn.registerObjectType<Assignee>('assignee', (c, id) => Assignee(c, id: id));

  daoTodo.changeStream.listen((objs) {
    objs.forEach(print);
    print(daoTodo.length);
  });

  daoAss.changeStream.listen((objs) => objs.forEach(print));

  final protocol = SyncLayerProtocol(syn);

  server.listen((HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket ws) {
      protocol.registerConnection(ws);
    }, onError: (err) => print('[!]Error -- ${err.toString()}'));
  }, onError: (err) => print('[!]Error -- ${err.toString()}'));
}
