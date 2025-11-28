import 'package:flutter/widgets.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:uuid/uuid.dart';

import 'view.dart';

const _uuid = Uuid();

@immutable
class Todo {
  const Todo({
    required this.description,
    required this.id,
    this.completed = false,
  });

  final String id;
  final String description;
  final bool completed;

  @override
  String toString() {
    return 'Todo(description: $description, completed: $completed)';
  }
}

enum TodoListFilter { all, active, completed }

class HomeState {
  List<Todo> todos;
  List<Todo> get filteredTodos {
    switch (filter) {
      case TodoListFilter.all:
        return todos;
      case TodoListFilter.active:
        return todos.where((todo) => !todo.completed).toList();
      case TodoListFilter.completed:
        return todos.where((todo) => todo.completed).toList();
    }
  }

  TodoListFilter filter;

  HomeState({required this.todos, this.filter = TodoListFilter.all});
}

class HomeController extends MvcController with MvcStatefulService<HomeState> {
  TextEditingController newTodoController = TextEditingController();

  void submitTodo(String value) {
    setState(
      (state) {
        state.todos = [
          ...state.todos,
          Todo(
            id: _uuid.v4(),
            description: value,
          ),
        ];
      },
    );
    newTodoController.clear();
  }

  void editTodo({required String id, required String description}) {
    setState(
      (state) {
        state.todos = state.todos
            .map(
              (todo) => todo.id == id
                  ? Todo(
                      id: todo.id,
                      description: description,
                      completed: todo.completed,
                    )
                  : todo,
            )
            .toList();
      },
    );
  }

  void deleteTodo(Todo todo) {
    setState(
      (state) {
        state.todos = state.todos.where((t) => t.id != todo.id).toList();
      },
    );
  }

  void toggleTodoCompletion(String id) {
    setState(
      (state) {
        state.todos = state.todos
            .map(
              (todo) => todo.id == id
                  ? Todo(
                      id: todo.id,
                      description: todo.description,
                      completed: !todo.completed,
                    )
                  : todo,
            )
            .toList();
      },
    );
  }

  void filterTodos(TodoListFilter filter) {
    setState(
      (state) {
        state.filter = filter;
      },
    );
  }

  @override
  MvcView<MvcController> view() {
    return HomeView();
  }

  @override
  HomeState initializeState() {
    return HomeState(todos: [
      const Todo(id: 'todo-0', description: 'Buy cookies'),
      const Todo(id: 'todo-1', description: 'Star flutter_mvc repo'),
      const Todo(id: 'todo-2', description: 'Have a walk'),
    ]);
  }
}
