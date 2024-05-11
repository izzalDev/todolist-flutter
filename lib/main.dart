import 'package:flutter/material.dart';
import 'package:todo_list/database_helper.dart';
import 'package:todo_list/todo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Todo-List App',
      home: TodoApp(),
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final dbHelper = DatabaseHelper();
  List<Todo> _todos = [];
  int _count = 0;

  @override
  void initState() {
    super.initState();
    refreshItemList();
  }

  void refreshItemList() async {
    _todos = await dbHelper.getAllTodos();
    _todos.sort((a, b) => a.completed == b.completed ? 0 : a.completed ? 1 : -1);
    setState(() {});
  }

  void searchItems() async {
    final keyword = _searchController.text.trim();
    _todos = keyword.isNotEmpty
        ? await dbHelper.getTodoByTitle(keyword)
        : await dbHelper.getAllTodos();
    setState(() {});
  }

  void addItem(String title, String desc) async {
    if (title.trim().isEmpty) {
      // Tampilkan pesan error atau lakukan tindakan lain
      return;
    }
    final todo = Todo(id: _count++, title: title, description: desc, completed: false);
    await dbHelper.insertTodo(todo);
    refreshItemList();
  }

  void updateItem(Todo todo, bool completed) async {
    final updatedTodo = todo.copyWith(completed: completed);
    await dbHelper.updateTodo(updatedTodo);
    refreshItemList();
  }

  void deleteItem(int id) async {
    await dbHelper.deleteTodo(id);
    refreshItemList();
  }

  void deleteCompletedItems() async {
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete) {
      await dbHelper.deleteCompletedTodos();
      refreshItemList();
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penghapusan'),
        content: const Text('Apakah Anda yakin ingin menghapus semua todo yang telah selesai?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    ) ?? false; // Mengembalikan false jika dialog ditutup tanpa memilih
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo List')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => searchItems(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return ListTile(
                  leading: IconButton(
                    icon: Icon(todo.completed ? Icons.check_circle : Icons.radio_button_unchecked),
                    onPressed: () => updateItem(todo, !todo.completed),
                  ),
                  title: Text(todo.title),
                  subtitle: Text(todo.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditTodoDialog(context, todo),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteItem(todo.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: deleteCompletedItems,
            heroTag: null,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                const Icon(Icons.delete_outline),
                Transform.translate(
                  offset: const Offset(10, 10),
                  child: const Icon(Icons.check_circle, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () => _showAddTodoDialog(context),
            heroTag: null,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Todo'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Judul todo'),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(hintText: 'Deskripsi todo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Batalkan'),
            onPressed: () {
              Navigator.pop(context);
              _titleController.clear();
              _descController.clear();
            },
          ),
          TextButton(
            child: const Text('Tambah'),
            onPressed: () {
              addItem(_titleController.text, _descController.text);
              _titleController.clear();
              _descController.clear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEditTodoDialog(BuildContext context, Todo todo) {
    _titleController.text = todo.title;
    _descController.text = todo.description;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Todo'),
        content: SizedBox(
          width: 200,
          height: 200,
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: 'Judul todo'),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(hintText: 'Deskripsi todo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Batalkan'),
            onPressed: () {
              Navigator.pop(context);
              _titleController.clear();
              _descController.clear();
            },
          ),
          TextButton(
            child: const Text('Simpan'),
            onPressed: () {
              updateItem(todo.copyWith(title: _titleController.text, description: _descController.text), todo.completed);
              _titleController.clear();
              _descController.clear();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}


