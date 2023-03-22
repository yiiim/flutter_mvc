import 'dart:async';

import 'package:dart_dependency_injection/src/dart_dependency_injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

class TestSingletonObject {}

class TestScopedSingletonObject {}

class TestObject {}

class DeepAsyncInitializeService with DependencyInjectionService {
  void Function()? didInit;
  @override
  Future dependencyInjectionServiceInitialize() async {
    print("Deep begin init");
    getService<AsyncInitializeService>();
    await Future.delayed(const Duration(seconds: 3));
    didInit?.call();
    print("Deep done init");
  }
}

class DeepAwaitAsyncInitializeService with DependencyInjectionService {
  void Function()? didInit;
  @override
  Future dependencyInjectionServiceInitialize() async {
    print("Deep Await begin init");
    getService<AsyncInitializeService>();
    await waitLatestServiceInitialize();
    await Future.delayed(const Duration(seconds: 3));
    didInit?.call();
    print("Deep Await done init");
  }
}

class AsyncInitializeService with DependencyInjectionService {
  void Function()? didInit;
  @override
  Future dependencyInjectionServiceInitialize() async {
    print("begin init");
    await Future.delayed(const Duration(seconds: 3));
    didInit?.call();
    print("done init");
  }
}

class TestPorxyController extends MvcProxyController {
  String text = "not init service";
  @override
  FutureOr dependencyInjectionServiceInitialize() {
    text = "init service";
  }
}

class TestScopedBuilderPorxyController extends MvcProxyController implements MvcServiceScopedBuilder {
  void Function(ServiceCollection collection)? onServiceScopedBuildBlock;
  @override
  void onServiceScopedBuild(ServiceCollection collection) {
    onServiceScopedBuildBlock?.call(collection);
  }
}

void main() {
  testWidgets(
    "test service get",
    (tester) async {
      var controller = TestPorxyController();
      var controller1 = TestPorxyController();
      await tester.pumpWidget(
        MvcDependencyProvider(
          provider: (collection) {
            collection.addSingleton<String>((serviceProvider) => "test");
            collection.addSingleton<TestSingletonObject>((serviceProvider) => TestSingletonObject());
            collection.addScopedSingleton<TestScopedSingletonObject>((serviceProvider) => TestScopedSingletonObject());
            collection.add<TestObject>((serviceProvider) => TestObject());
          },
          child: MvcProxy(
            proxyCreate: () => controller,
            child: MvcProxy(
              proxyCreate: () => controller1,
              child: Builder(
                builder: (context) {
                  return Text(controller.getService<String>(), textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text("test"), findsOneWidget);
      expect(controller.getService<TestSingletonObject>().hashCode == controller.getService<TestSingletonObject>().hashCode, isTrue);
      expect(controller.getService<TestScopedSingletonObject>().hashCode == controller.getService<TestScopedSingletonObject>().hashCode, isTrue);
      expect(controller.getService<TestObject>().hashCode != controller.getService<TestObject>().hashCode, isTrue);

      expect(controller1.getService<TestSingletonObject>().hashCode == controller1.getService<TestSingletonObject>().hashCode, isTrue);
      expect(controller1.getService<TestScopedSingletonObject>().hashCode == controller1.getService<TestScopedSingletonObject>().hashCode, isTrue);
      expect(controller1.getService<TestObject>().hashCode != controller1.getService<TestObject>().hashCode, isTrue);

      expect(controller.getService<TestSingletonObject>().hashCode == controller1.getService<TestSingletonObject>().hashCode, isTrue);
      expect(controller.getService<TestScopedSingletonObject>().hashCode != controller1.getService<TestScopedSingletonObject>().hashCode, isTrue);
      expect(controller.getService<TestObject>().hashCode != controller1.getService<TestObject>().hashCode, isTrue);
    },
  );

  testWidgets(
    "test service init",
    (tester) async {
      var controller = TestPorxyController();
      await tester.pumpWidget(
        MvcProxy(
          proxyCreate: () => controller,
          child: Builder(
            builder: (context) {
              return Text(controller.text, textDirection: TextDirection.ltr);
            },
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text("init service"), findsOneWidget);
    },
  );
  testWidgets(
    "test service async init",
    (tester) async {
      var controller = TestPorxyController();
      await tester.pumpWidget(
        MvcDependencyProvider(
          child: MvcProxy(
            proxyCreate: () => controller,
            child: const Placeholder(),
          ),
          provider: (collection) {
            collection.add((serviceProvider) => AsyncInitializeService());
            collection.add((serviceProvider) => DeepAsyncInitializeService());
            collection.add((serviceProvider) => DeepAwaitAsyncInitializeService());
          },
        ),
      );
      expect(find.text("wait init"), findsOneWidget);
      await controller.waitLatestServiceInitialize();
      expect(find.text("did init"), findsOneWidget);
    },
  );

  testWidgets(
    "test MvcServiceScopedBuilder",
    (tester) async {
      var controller = TestPorxyController();
      var controller1 = TestPorxyController();
      var copedBuilderController = TestScopedBuilderPorxyController();
      copedBuilderController.onServiceScopedBuildBlock = (collection) {
        collection.addSingleton<String>((serviceProvider) => "test_scoped");
        collection.addSingleton<TestSingletonObject>((serviceProvider) => TestSingletonObject());
        collection.add<TestObject>((serviceProvider) => TestObject());
      };

      await tester.pumpWidget(
        MvcDependencyProvider(
          provider: (collection) {
            collection.addSingleton<String>((serviceProvider) => "test");
            collection.addSingleton<TestSingletonObject>((serviceProvider) => TestSingletonObject());
          },
          child: Column(
            children: [
              MvcProxy(
                proxyCreate: () => copedBuilderController,
                child: MvcProxy(
                  proxyCreate: () => controller,
                  child: Builder(
                    builder: (context) {
                      return Text("1.${controller.getService<String>()}", textDirection: TextDirection.ltr);
                    },
                  ),
                ),
              ),
              MvcProxy(
                proxyCreate: () => controller1,
                child: Builder(
                  builder: (context) {
                    return Text("2.${controller1.getService<String>()}", textDirection: TextDirection.ltr);
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("1.test_scoped"), findsOneWidget);
      expect(find.text("2.test"), findsOneWidget);
      expect(controller.getService<TestSingletonObject>().hashCode != controller1.getService<TestSingletonObject>().hashCode, isTrue);
      expect(controller.getService<TestSingletonObject>().hashCode == copedBuilderController.getService<TestSingletonObject>().hashCode, isTrue);

      expect(controller.tryGetService<TestObject>() != null, isTrue);
      expect(controller1.tryGetService<TestObject>() == null, isTrue);
    },
  );
}
