import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:todos/home/controller.dart';

class HomeView extends MvcView<HomeController> {
  @override
  Widget buildView() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Builder(builder: (context) {
          final todos = context.stateAccessor.useState(
            (HomeState state) => state.filteredTodos,
            comparer: (oldState, newState) => listEquals(oldState, newState),
          );
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            children: [
              const Title(),
              TextField(
                controller: controller.newTodoController,
                decoration: const InputDecoration(labelText: 'What needs to be done?'),
                onSubmitted: controller.submitTodo,
              ),
              const SizedBox(height: 42),
              const Toolbar(),
              if (todos.isNotEmpty) const Divider(height: 0),
              for (var i = 0; i < todos.length; i++) ...[
                if (i > 0) const Divider(height: 0),
                Dismissible(
                  key: ValueKey(todos[i].id),
                  onDismissed: (_) {
                    controller.deleteTodo(todos[i]);
                  },
                  child: TodoItem(todo: todos[i]),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

class Title extends StatelessWidget {
  const Title({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'todos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

class Toolbar extends StatelessWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.stateAccessor.useState((HomeState state) => state.filter);
    final controller = context.getService<HomeController>();

    Color? textColorFor(TodoListFilter value) {
      return filter == value ? Colors.blue : Colors.black;
    }

    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final uncompletedCount = context.stateAccessor.useState(
                  (HomeState state) => state.todos.where((todo) => !todo.completed).length,
                );
                return Text(
                  '$uncompletedCount items left',
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
          Tooltip(
            message: 'All todos',
            child: TextButton(
              onPressed: () => controller.filterTodos(TodoListFilter.all),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStatePropertyAll(
                  textColorFor(TodoListFilter.all),
                ),
              ),
              child: const Text('All'),
            ),
          ),
          Tooltip(
            message: 'Only uncompleted todos',
            child: TextButton(
              onPressed: () => controller.filterTodos(TodoListFilter.active),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStatePropertyAll(
                  textColorFor(TodoListFilter.active),
                ),
              ),
              child: const Text('Active'),
            ),
          ),
          Tooltip(
            message: 'Only completed todos',
            child: TextButton(
              onPressed: () => controller.filterTodos(TodoListFilter.completed),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStatePropertyAll(
                  textColorFor(TodoListFilter.completed),
                ),
              ),
              child: const Text('Completed'),
            ),
          ),
        ],
      ),
    );
  }
}

class TodoItem extends StatefulWidget {
  const TodoItem({super.key, required this.todo});
  final Todo todo;

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  final FocusNode _itemFocusNode = FocusNode();
  final FocusNode _textFieldFocusNode = FocusNode();
  late final TextEditingController _textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = context.getService<HomeController>();
    return Material(
      color: Colors.white,
      elevation: 6,
      child: Focus(
        focusNode: _itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            _textEditingController.text = widget.todo.description;
          } else {
            controller.editTodo(id: widget.todo.id, description: _textEditingController.text);
            _textEditingController.text = '';
          }
        },
        child: ListTile(
          onTap: () {
            _itemFocusNode.requestFocus();
            _textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
            value: widget.todo.completed,
            onChanged: (value) => controller.toggleTodoCompletion(widget.todo.id),
          ),
          title: Builder(
            builder: (context) {
              return Focus.of(context).hasFocus
                  ? TextField(
                      autofocus: true,
                      focusNode: _textFieldFocusNode,
                      controller: _textEditingController,
                    )
                  : Text(widget.todo.description);
            },
          ),
        ),
      ),
    );
  }
}
