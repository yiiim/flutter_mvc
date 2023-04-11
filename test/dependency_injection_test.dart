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
    getService<AsyncInitializeService>();
    await Future.delayed(const Duration(seconds: 3));
    didInit?.call();
  }
}

class DeepAwaitAsyncInitializeService with DependencyInjectionService {
  void Function()? didInit;
  @override
  Future dependencyInjectionServiceInitialize() async {
    getService<AsyncInitializeService>();
    await waitLatestServiceInitialize();
    await Future.delayed(const Duration(seconds: 3));
    didInit?.call();
  }
}

class AsyncInitializeService with DependencyInjectionService {
  void Function()? didInit;
  @override
  Future dependencyInjectionServiceInitialize() async {
    await Future.delayed(const Duration(seconds: 3));
    didInit?.call();
  }
}

class TestPorxyController extends MvcProxyController {
  String text = "test";
}

class TestScopedBuilderPorxyController extends MvcProxyController {
  void Function(ServiceCollection collection)? onServiceScopedBuildBlock;
  @override
  void buildScopedService(ServiceCollection collection) {
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
    "test MvcControllerProvider",
    (tester) async {
      await tester.pumpWidget(
        MvcDependencyProvider(
          provider: (collection) {
            collection.addController<TestPorxyController>((p) => TestPorxyController());
          },
          child: Mvc<TestPorxyController, Widget>(
            model: const Text("test", textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(find.text("test"), findsOneWidget);
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
