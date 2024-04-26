import 'package:todo_list/todo.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _db;

  Future<Database?> get db async {
    if (_db != null) return _db;
    _db = await initDb();
    return _db;
  }

  DatabaseHelper.internal();

  Future<Database> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(
      documentsDirectory.path,
      'todolist.db',
    );
    var theDb = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    return theDb;
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE 
        IF NOT EXISTS todos 
        (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          completed INTEGER NOT NULL
        )   
        ''');
  }

  Future<List<Todo>> getAllTodos() async {
    var dbClient = await db;
    var todos = await dbClient!.query('todos');
    return todos.map((todo) => Todo.fromMap(todo)).toList();
  }

  Future<Todo> getTodoById(int id) async {
    var dbClient = await db;
    var todo = await dbClient!.query('todos', where: 'id = ?', whereArgs: [id]);
    return todo.map((todo) => Todo.fromMap(todo)).single;
  }

  Future<List<Todo>> getTodoByTitle(String title) async {
    var dbClient = await db;
    var todo = await dbClient!
        .query('todos', where: 'title like ?', whereArgs: [title]);
    return todo.map((todo) => Todo.fromMap(todo)).toList();
  }

  Future<int> insertTodo(Todo todo) async {
    var dbClient = await db;
    return await dbClient!.insert('todos', todo.toMap());
  }

  Future<int> updateTodo(Todo todo) async {
    var dbClient = await db;
    return await dbClient!
        .update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<int> deleteTodo(int id) async {
    var dbClient = await db;
    return await dbClient!.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}
