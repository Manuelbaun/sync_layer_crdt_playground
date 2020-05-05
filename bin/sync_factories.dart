import 'dart:async';

import 'package:sync_layer/basic/cuid.dart';
import 'package:sync_layer/db/index.dart';
import 'package:sync_layer/db/row.dart';
import 'package:sync_layer/sync/sync_imple.dart';
import 'package:sync_layer/utils/measure.dart';

class Todo {
  final Row _row;

  Todo(this._row, {String title, bool status}) : assert(_row != null) {
    this.title ??= title;
    this.status ??= status;
  }

  String get title => _row['title'];
  set title(String v) => _row['title'] = v;

  bool get status => _row['status'];
  set status(bool v) => _row['status'] = v;

  Assignee get assignee => _row['assignee'];
  set assignee(Assignee v) => _row['assignee'] = v;

  @override
  String toString() {
    final rowData = _row.toString();
    return 'Todo($rowData , lastUpdated: ${_row.lastUpdated})';
  }
}

class TodoTable extends Table {
  TodoTable(String name, SyncLayerImpl syn) : super(name, syn);

  Todo create(String title, {bool status = false}) {
    final row = getRow(newCuid());
    return Todo(row, title: title, status: status);
  }

  Todo read(String id) {
    return Todo(getRow(id));
  }

  Todo update() {}
  bool delete() {}
}

class Assignee {
  final Row row;

  Assignee(this.row, {String department, String firstname, String lastname}) : assert(row != null) {
    this.department = department;
    this.firstname = firstname;
    this.lastname = lastname;
  }

  String get department => row['department'];
  set department(String value) => row['department'] = value;

  String get firstname => row['firstname'];
  set firstname(String value) => row['firstname'] = value;

  String get lastname => row['lastname'];
  set lastname(String value) => row['lastname'] = value;

  @override
  String toString() {
    return 'Assignee(${row.obj}: lastUpdated:${row.lastUpdated})';
  }
}

SyncLayerImpl createNode(String name) {
  final syn = SyncLayerImpl(name);

  syn.db.registerTable(TodoTable('todo', syn));
  syn.db.registerTable(AssigneeTable('assingee', syn));

  return syn;
}

class AssigneeTable extends Table {
  AssigneeTable(String name, SyncLayerImpl syn) : super(name, syn);

  Assignee create(String department, String firstname, String lastname) {
    final row = getRow(newCuid());
    return Assignee(row, department: department, firstname: firstname, lastname: lastname);
  }

  Assignee read(String id) {
    return Assignee(getRow(id));
  }

  Assignee update() {}
  bool delete() {}
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
  final todo1 = tab1.create('My first todo');
  final todo2 = tab1.create('My second todo');

  final tab21 = syn2.db.getTable('todo') as TodoTable;
  final todo21 = tab21.read(todo1._row.id);
  todo21.status = true;

  final tab11 = syn1.db.getTable('todo') as TodoTable;
  final tabAss = syn1.db.getTable('assingee') as AssigneeTable;
  final a1 = tabAss.create('House', 'Manu', 'Bun');

  final todo11 = tab11.read(todo2._row.id);
  todo11.assignee = a1;

  todo11.status = true;

  s.stop();

  print(s.elapsedMicroseconds);

  syn.db.getTable('todo').rows.values.forEach(print);
  syn1.db.getTable('todo').rows.values.forEach(print);
  syn2.db.getTable('todo').rows.values.forEach(print);

  // print(todo1);
  print(todo2);

  todo2.assignee.department = 'Firebase';

  print(todo11);
  // syn.db.getTable('todo').rows.values.forEach(print);
  // syn1.db.getTable('todo').rows.values.forEach(print);
  // syn2.db.getTable('todo').rows.values.forEach(print);

  // Timer.periodic(Duration(milliseconds: 2000), (t) {
  //   final todo = tab1.create('Next Todo ${t.tick}');
  //   print(todo);

  //   final to = tab11.read(todo._row.id);
  //   final to2 = tab21.read(todo._row.id);

  //   Timer(Duration(milliseconds: 100), () {
  //     to.status = true;
  //     print(todo);
  //     print(to);
  //     print(to2);
  //   });
  // });
}
