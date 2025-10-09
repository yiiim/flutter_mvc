import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MvcStatelessWidget', () {
    testWidgets('should create widget with id', (tester) async {
      const testId = 'test-widget-id';
      await tester.pumpWidget(
        MvcApp(
          child: TestStatelessWidget(
            id: testId,
            builder: (context) => const Text('Test', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should create widget with classes', (tester) async {
      const testClasses = ['class1', 'class2'];
      await tester.pumpWidget(
        MvcApp(
          child: TestStatelessWidget(
            classes: testClasses,
            builder: (context) => const Text('Test', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should create widget with attributes', (tester) async {
      final testAttributes = {'key1': 'value1', 'key2': 'value2'};
      await tester.pumpWidget(
        MvcApp(
          child: TestStatelessWidget(
            attributes: testAttributes,
            builder: (context) => const Text('Test', textDirection: TextDirection.ltr),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should access MvcContext from build method', (tester) async {
      MvcContext? capturedContext;
      await tester.pumpWidget(
        MvcApp(
          child: TestStatelessWidget(
            builder: (context) {
              capturedContext = context as MvcContext;
              return const Text('Test', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(capturedContext, isNotNull);
      expect(capturedContext!.scope, isA<MvcWidgetScope>());
    });
  });

  group('MvcStatefulWidget', () {
    testWidgets('should create stateful widget with id', (tester) async {
      const testId = 'test-stateful-id';
      await tester.pumpWidget(
        const MvcApp(
          child: TestStatefulWidget(
            id: testId,
            text: 'Initial',
          ),
        ),
      );

      expect(find.text('Initial'), findsOneWidget);
    });

    testWidgets('should create stateful widget with classes', (tester) async {
      const testClasses = ['stateful-class'];
      await tester.pumpWidget(
        const MvcApp(
          child: TestStatefulWidget(
            classes: testClasses,
            text: 'Test',
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should access MvcContext from state', (tester) async {
      MvcContext? capturedContext;
      await tester.pumpWidget(
        MvcApp(
          child: TestStatefulWidget(
            text: 'Test',
            onBuild: (context) {
              capturedContext = context;
            },
          ),
        ),
      );

      expect(capturedContext, isNotNull);
      expect(capturedContext!.scope, isA<MvcWidgetScope>());
    });

    testWidgets('should call initServices when created', (tester) async {
      bool serviceInitialized = false;
      await tester.pumpWidget(
        MvcApp(
          child: TestStatefulWidgetWithService(
            onServiceInit: () {
              serviceInitialized = true;
            },
          ),
        ),
      );

      expect(serviceInitialized, isTrue);
    });

    testWidgets('should dispose properly', (tester) async {
      bool disposed = false;
      await tester.pumpWidget(
        MvcApp(
          child: TestStatefulWidgetWithDispose(
            onDispose: () {
              disposed = true;
            },
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox());
      expect(disposed, isTrue);
    });

    testWidgets('should have isSelectorBreaker property', (tester) async {
      await tester.pumpWidget(
        const MvcApp(
          child: TestStatefulWidgetWithSelectorBreaker(
            isSelectorBreaker: true,
            text: 'Test',
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should have createStateScope property', (tester) async {
      await tester.pumpWidget(
        const MvcApp(
          child: TestStatefulWidgetWithStateScope(
            createStateScope: true,
            text: 'Test',
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('MvcDependencyProvider', () {
    testWidgets('should provide services to descendants', (tester) async {
      final testService = TestMvcService(value: 'test-value');
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestMvcService>((_) => testService);
            },
            child: Builder(
              builder: (context) {
                final service = context.getMvcService<TestMvcService>();
                return Text(service.value, textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      );

      expect(find.text('test-value'), findsOneWidget);
    });

    testWidgets('should override parent services', (tester) async {
      await tester.pumpWidget(
        MvcApp(
          child: MvcDependencyProvider(
            provider: (collection) {
              collection.addSingleton<TestMvcService>((_) => TestMvcService(value: 'parent'));
            },
            child: MvcDependencyProvider(
              provider: (collection) {
                collection.addSingleton<TestMvcService>((_) => TestMvcService(value: 'child'));
              },
              child: Builder(
                builder: (context) {
                  final service = context.getMvcService<TestMvcService>();
                  return Text(service.value, textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('child'), findsOneWidget);
    });
  });
}

// Test helper widgets
class TestStatelessWidget extends MvcStatelessWidget {
  const TestStatelessWidget({
    super.id,
    super.classes,
    super.attributes,
    required this.builder,
    super.key,
  });

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

class TestStatefulWidget extends MvcStatefulWidget {
  const TestStatefulWidget({
    super.id,
    super.classes,
    super.attributes,
    required this.text,
    this.onBuild,
    super.key,
  });

  final String text;
  final void Function(MvcContext context)? onBuild;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _TestStatefulWidgetState();
}

class _TestStatefulWidgetState extends MvcWidgetState<TestStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    widget.onBuild?.call(this.context);
    return Text(widget.text, textDirection: TextDirection.ltr);
  }
}

class TestStatefulWidgetWithService extends MvcStatefulWidget {
  const TestStatefulWidgetWithService({
    required this.onServiceInit,
    super.key,
  });

  final VoidCallback onServiceInit;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _TestStatefulWidgetWithServiceState();
}

class _TestStatefulWidgetWithServiceState extends MvcWidgetState<TestStatefulWidgetWithService> {
  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
    widget.onServiceInit();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class TestStatefulWidgetWithDispose extends MvcStatefulWidget {
  const TestStatefulWidgetWithDispose({
    required this.onDispose,
    super.key,
  });

  final VoidCallback onDispose;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _TestStatefulWidgetWithDisposeState();
}

class _TestStatefulWidgetWithDisposeState extends MvcWidgetState<TestStatefulWidgetWithDispose> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class TestStatefulWidgetWithSelectorBreaker extends MvcStatefulWidget {
  const TestStatefulWidgetWithSelectorBreaker({
    required this.isSelectorBreaker,
    required this.text,
    super.key,
  });

  final bool isSelectorBreaker;
  final String text;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _TestStatefulWidgetWithSelectorBreakerState();
}

class _TestStatefulWidgetWithSelectorBreakerState extends MvcWidgetState<TestStatefulWidgetWithSelectorBreaker> {
  @override
  bool get isSelectorBreaker => widget.isSelectorBreaker;

  @override
  Widget build(BuildContext context) {
    return Text(widget.text, textDirection: TextDirection.ltr);
  }
}

class TestStatefulWidgetWithStateScope extends MvcStatefulWidget {
  const TestStatefulWidgetWithStateScope({
    required this.createStateScope,
    required this.text,
    super.key,
  });

  final bool createStateScope;
  final String text;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _TestStatefulWidgetWithStateScopeState();
}

class _TestStatefulWidgetWithStateScopeState extends MvcWidgetState<TestStatefulWidgetWithStateScope> {
  @override
  bool get createStateScope => widget.createStateScope;

  @override
  Widget build(BuildContext context) {
    return Text(widget.text, textDirection: TextDirection.ltr);
  }
}

class TestMvcService with DependencyInjectionService {
  TestMvcService({required this.value});
  final String value;
}
