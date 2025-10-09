# 依赖于对象

你可以让单个 Widget 依赖于特定类型的对象，通过对象更新来触发 Widget 的重建。

## 快速开始

下面是一个简单的计数器示例，展示了如何使用对象来更新 Widget。

```dart
class CounterService with MvcDependableObject {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyAllDependents();
  }
}

void main() {
  runApp(
    MaterialApp(
      home: MvcApp(
        child: MvcDependencyProvider(
          provider: (collection) {
            collection.addSingleton<CounterService>((_) => CounterService());
          },
          child: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  final counterService = context.dependOnMvcServiceOfExactType<CounterService>();
                  return Text(
                    '${counterService.count}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            ),
            floatingActionButton: Builder(
              builder: (context) {
                return FloatingActionButton(
                  onPressed: () {
                    context.getMvcService<CounterService>().increment();
                  },
                  tooltip: 'Increment',
                  child: const Icon(Icons.add),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
```

你需要注意注入依赖时的类型，通常应该注入单例。
