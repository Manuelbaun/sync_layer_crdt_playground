// import 'dart:async';
// import 'dart:math';

// final rand = Random(0);

// abstract class Todo extends SynableObject {
//   Todo(String id) : super(id);

//   String title;
//   DateTime deadline;
//   bool done;
// }

// class TodoTable extends SyncableTable<Todo> {
//   TodoTable() : super(0, 'todo');

//   final _streamController = StreamController<Todo>();

//   void addTodo(Todo) {

//     emitMessage()
//   }

//   void updateTodo() {}

//   @override
//   void applyMessage(updateMessage) {

//     final index = updateMessage.id;
//     final msg = updateMessage.msg;

//     if(table.containsKey(msg.row)){

//       table[msg.row].set(msg.values);

//       _streamController.add(null);
//     } else {
//       // ADD
//     }

//   }

// }

// SyncLayerImpl createSyncLayer() {
//   final node = SyncLayerImpl(rand.nextInt(0xffffffff));
//   // Register all Tables
//   node.registerTable<Todo>(TodoTable());
//   return node;
// }

// void main() {
//   final localNode = createSyncLayer();
//   final remoteNode = createSyncLayer();

//   final todoTable = localNode.getTable('todo') as TodoTable;

//   todoTable.stream.listen((todo) {
//     print(todo);
//   });

//   print(todoTable);
// }
