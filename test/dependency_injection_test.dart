import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dependency Injection', () {
    group('Service Registration and Retrieval', () {
      testWidgets('getMvcService gets registered service', (tester) async {
        await tester.pumpWidget(
          MvcApp(
            serviceProviderBuilder: (collection) {
              collection.addSingleton<_TestService>(
                (_) => _TestService('Test Value'),
              );
            },
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    final service = context.getMvcService<_TestService>();
                    return Text(service.value);
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Test Value'), findsOneWidget);
      });

      testWidgets('MvcDependencyProvider provides scoped services', (tester) async {
        await tester.pumpWidget(
          MvcApp(
            child: MaterialApp(
              home: MvcDependencyProvider(
                provider: (collection) {
                  collection.addSingleton<_TestService>(
                    (_) => _TestService('Scoped Value'),
                  );
                },
                child: Scaffold(
                  body: Builder(
                    builder: (context) {
                      final service = context.getMvcService<_TestService>();
                      return Text(service.value);
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Scoped Value'), findsOneWidget);
      });

      testWidgets('child scope can override parent service', (tester) async {
        await tester.pumpWidget(
          MvcApp(
            serviceProviderBuilder: (collection) {
              collection.addSingleton<_TestService>(
                (_) => _TestService('Parent'),
              );
            },
            child: MaterialApp(
              home: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final service = context.getMvcService<_TestService>();
                      return Text('Parent: ${service.value}');
                    },
                  ),
                  MvcDependencyProvider(
                    provider: (collection) {
                      collection.addSingleton<_TestService>(
                        (_) => _TestService('Child'),
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        final service = context.getMvcService<_TestService>();
                        return Text('Child: ${service.value}');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Parent: Parent'), findsOneWidget);
        expect(find.text('Child: Child'), findsOneWidget);
      });
    });

    group('Service Lifecycles', () {
      testWidgets('singleton returns same instance', (tester) async {
        _TestService? instance1;
        _TestService? instance2;

        await tester.pumpWidget(
          MvcApp(
            serviceProviderBuilder: (collection) {
              collection.addSingleton<_TestService>(
                (_) => _TestService('Singleton'),
              );
            },
            child: MaterialApp(
              home: Column(
                children: [
                  Builder(
                    builder: (context) {
                      instance1 = context.getMvcService<_TestService>();
                      return Text('Instance 1: ${instance1!.value}');
                    },
                  ),
                  Builder(
                    builder: (context) {
                      instance2 = context.getMvcService<_TestService>();
                      return Text('Instance 2: ${instance2!.value}');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(instance1, same(instance2));
      });

      testWidgets('transient returns new instance each time', (tester) async {
        _TestService? instance1;
        _TestService? instance2;

        await tester.pumpWidget(
          MvcApp(
            serviceProviderBuilder: (collection) {
              collection.add<_TestService>(
                (_) => _TestService('Transient'),
              );
            },
            child: MaterialApp(
              home: Column(
                children: [
                  Builder(
                    builder: (context) {
                      instance1 = context.getMvcService<_TestService>();
                      return Text('Instance 1: ${instance1!.value}');
                    },
                  ),
                  Builder(
                    builder: (context) {
                      instance2 = context.getMvcService<_TestService>();
                      return Text('Instance 2: ${instance2!.value}');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(instance1, isNot(same(instance2)));
      });
    });

    group('Controller Service Registration', () {
      testWidgets('controller can register services', (tester) async {
        await tester.pumpWidget(
          const MvcApp(
            child: MaterialApp(
              home: Mvc<_ServiceRegisteringController, void>(
                create: _ServiceRegisteringController.new,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Controller Service: Hello'), findsOneWidget);
      });

      testWidgets('MvcControllerServiceCollection.addController works', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MvcApp(
              child: MvcDependencyProvider(
                provider: (collection) {
                  collection.addController<_SimpleController>(
                    (_) => _SimpleController(),
                  );
                },
                child: const Mvc<_SimpleController, void>(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Simple'), findsOneWidget);
      });
    });

    group('Service Dependencies', () {
      testWidgets('service can depend on other services', (tester) async {
        await tester.pumpWidget(
          MvcApp(
            serviceProviderBuilder: (collection) {
              collection.addSingleton<_BaseService>(
                (_) => _BaseService('Base'),
              );
              collection.addSingleton<_DependentService>(
                (provider) => _DependentService(
                  provider.get<_BaseService>(),
                ),
              );
            },
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    final service = context.getMvcService<_DependentService>();
                    return Text(service.getMessage());
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dependent uses: Base'), findsOneWidget);
      });
    });
  });
}

// Test Services
class _TestService {
  _TestService(this.value);
  final String value;
}

class _BaseService {
  _BaseService(this.name);
  final String name;
}

class _DependentService {
  _DependentService(this.baseService);
  final _BaseService baseService;

  String getMessage() => 'Dependent uses: ${baseService.name}';
}

class _ServiceRegisteringController extends MvcController<void> {
  @override
  void initServices(ServiceCollection collection) {
    super.initServices(collection);
    collection.addSingleton<_TestService>(
      (_) => _TestService('Hello'),
    );
  }

  @override
  MvcView view() => _ServiceRegisteringView();
}

class _ServiceRegisteringView extends MvcView<_ServiceRegisteringController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Builder(
        builder: (context) {
          final service = context.getMvcService<_TestService>();
          return Text('Controller Service: ${service.value}');
        },
      ),
    );
  }
}

class _SimpleController extends MvcController<void> {
  @override
  MvcView view() => _SimpleView();
}

class _SimpleView extends MvcView<_SimpleController> {
  @override
  Widget buildView() {
    return const Scaffold(
      body: Text('Simple'),
    );
  }
}
