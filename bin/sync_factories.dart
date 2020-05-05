import 'dart:async';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/db/index.dart';
import 'package:sync_layer/db/row.dart';
import 'package:sync_layer/sync/sync_imple.dart';
import 'package:sync_layer/utils/measure.dart';

class Todo {
  final Row _row;

  Todo(this._row, {String title, bool status, DateTime lastUpdated}) : assert(_row != null) {
    this.title ??= title;
    this.status ??= status;
    this.lastUpdated ??= lastUpdated;
  }

  String get title => _row['title'];
  set title(String v) => _row['title'] = v;

  bool get status => _row['status'];
  set status(bool v) => _row['status'] = v;

  DateTime get lastUpdated => DateTime.fromMillisecondsSinceEpoch(_row['lastUpdated'] ?? 0);
  set lastUpdated(DateTime v) => _row['lastUpdated'] = v.millisecondsSinceEpoch;

  @override
  String toString() {
    final rowData = _row.toString();
    return 'Todo($rowData)';
  }
}

SyncLayerImpl createNode(String name) {
  final syn = SyncLayerImpl(name);

  syn.db.registerTable(TodoTable('todo', syn));

  return syn;
}

void main() {
  final syn = createNode('local');
  final syn1 = createNode('remote 1');
  final syn2 = createNode('remote 2');

  final s = Stopwatch()..start();

  /// send via network!
  syn.onChange = (rows, tables) {
    // print('change on ${syn.nodeId}');
    measureExecution('Sync 1 mit 0', () {
      syn1.applyMessages(syn.getDiffMessagesFromIncomingMerkleTrie(syn1.trie.toMap()));
    });
    measureExecution('Sync 2 mit 0', () {
      syn2.applyMessages(syn.getDiffMessagesFromIncomingMerkleTrie(syn2.trie.toMap()));
    });
  };

  syn1.onChange = (rows, tables) {
    measureExecution('Sync 0 mit 1', () {
      syn.applyMessages(syn1.getDiffMessagesFromIncomingMerkleTrie(syn.trie.toMap()));
    });
    measureExecution('Sync 2 mit 1', () {
      syn2.applyMessages(syn1.getDiffMessagesFromIncomingMerkleTrie(syn2.trie.toMap()));
    });
  };

  syn2.onChange = (rows, tables) {
    measureExecution('Sync 0 mit 2', () {
      syn.applyMessages(syn2.getDiffMessagesFromIncomingMerkleTrie(syn.trie.toMap()));
    });
    measureExecution('Sync 1 mit 2', () {
      syn1.applyMessages(syn2.getDiffMessagesFromIncomingMerkleTrie(syn1.trie.toMap()));
    });
  };

  final tab1 = syn.db.getTable('todo') as TodoTable;
  final todo1 = tab1.createTodo('My first todo');
  final todo2 = tab1.createTodo('My second todo');

  final tab21 = syn2.db.getTable('todo') as TodoTable;
  final todo21 = tab21.readTodo(todo1._row.id);
  todo21.status = true;

  final tab11 = syn1.db.getTable('todo') as TodoTable;
  final todo11 = tab11.readTodo(todo2._row.id);
  todo11.status = true;

  s.stop();

  print(s.elapsedMicroseconds);

  syn.db.allMessages.forEach(print);
  print('---');
  syn1.db.allMessages.forEach(print);
  print('---');
  syn2.db.allMessages.forEach(print);

  // print(todo1);
  print(todo2);

  Timer.periodic(Duration(milliseconds: 50), (t) {
    final todo = tab1.createTodo('Next Todo ${t.tick}');
    print(todo);

    final to = tab11.readTodo(todo._row.id);
    final to2 = tab21.readTodo(todo._row.id);

    Timer(Duration(milliseconds: 10), () {
      to.status = true;
      print(todo);
      print(to);
      print(to2);
    });
  });
}

class TodoTable extends Table {
  TodoTable(String name, SyncLayerImpl syn) : super(name, syn);

  Todo createTodo(String title, {bool status = false, DateTime date}) {
    final row = getRow(newCuid());
    return Todo(row, title: title, status: status, lastUpdated: date);
  }

  Todo readTodo(String id) {
    return Todo(getRow(id));
  }

  Todo updateTodo() {}
  bool deleteTodo() {}
}

// class Assignee {
//   final Row row;

//   Assignee(this.row, {String department, String firstname, String lastname}) : assert(row != null) {
//     this.department = department;
//     this.firstname = firstname;
//     this.lastname = lastname;
//   }

//   String get department => row['department'];
//   set department(String value) => row['department'] = value;

//   String get firstname => row['firstname'];
//   set firstname(String value) => row['firstname'] = value;

//   String get lastname => row['lastname'];
//   set lastname(String value) => row['lastname'] = value;
// }
