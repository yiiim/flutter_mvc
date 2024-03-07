import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';

/// use [MvcController.querySelectorAll] to update it in controller
///
/// example:
/// ```dart
/// ...
/// MvcBuilder(
///   id: "title",
///   classes: ["title"],
///   builder: (controller) => Text(controller.title),
/// )
/// // in controller
/// class TestController extends MvcController {
///   String title = "title";
///   void updateTitleWithId() {
///     querySelectorAll("#title").update(() => title = "new title");  // update with id
///   }
///   void updateTitleWithClasses() {
///     querySelectorAll(".title").update(() => title = "new title");  // update with classes
///   }
/// }
/// ```
class MvcBuilder extends MvcStatelessWidget {
  const MvcBuilder({super.key, super.classes, super.id, super.attributes, required this.builder});
  final Widget Function(MvcContext context) builder;
  @override
  Widget build(BuildContext context) {
    return builder(context as MvcContext);
  }
}

/// use [MvcController.querySelectorAll] to update it in controller
///
/// example:
/// ```dart
/// class TestController extends MvcController {
///   String title = "title";
///   void updateHeader() {
///     querySelectorAll<MvcHeader>().update();
///   }
/// }
/// ```
class MvcHeader extends MvcBuilder {
  const MvcHeader({required super.builder, super.id, super.classes, super.attributes, super.key});
}

/// use [MvcController.querySelectorAll] to update it in controller
///
/// example:
/// ```dart
/// class TestController extends MvcController {
///   String title = "title";
///   void updateBody() {
///     querySelectorAll<MvcBody>().update();
///   }
/// }
/// ```
class MvcBody extends MvcBuilder {
  const MvcBody({required super.builder, super.id, super.classes, super.attributes, super.key});
}

/// use [MvcController.querySelectorAll] to update it in controller
///
/// example:
/// ```dart
/// class TestController extends MvcController {
///   String title = "title";
///   void updateFooter() {
///     querySelectorAll<MvcFooter>().update();
///   }
/// }
/// ```
class MvcFooter extends MvcBuilder {
  const MvcFooter({required super.builder, super.id, super.classes, super.attributes, super.key});
}

/// You can update this Widget using the following methods：
/// ## update at controlle
/// ```dart
/// // in the MvcView
/// MvcServiceScope<TestService>(
///    builder: (context, service) {
///       return Text(service.title);
///    },
/// )
///
/// // in the MvcController, will be update all MvcServiceScope<TestService>
/// getService<TestService>().update();
/// ```
/// ---
/// ## update at the service
///
/// ```dart
/// // anywhere
/// MvcServiceScope<TestService>(
///    builder: (context, service) {
///       return Text(service.title);
///    },
/// )
///
/// // in the TestService
/// class TestService with DependencyInjectionService, MvcService {
///   String title = "Test Title";
///   void changeTitle(String newTitle) {
///     title = newTitle;
///     // will be update all MvcServiceScope<TestService>
///     update();
///   }
/// }
/// ```
class MvcServiceScope<TServiceType extends MvcService> extends MvcStatefulWidget {
  const MvcServiceScope({required this.builder, super.id, super.classes, super.attributes, super.key});
  final Widget Function(MvcContext context, TServiceType) builder;

  @override
  MvcWidgetState<MvcStatefulWidget> createState() => _MvcServiceScopeState<TServiceType>();
}

class _MvcServiceScopeState<TServiceType extends MvcService> extends MvcWidgetState<MvcServiceScope<TServiceType>> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(this.context, this.context.dependOnService<TServiceType>());
  }
}

/// We can use [MvcApp] to provide initial services.
class MvcApp extends MvcStatelessWidget implements MvcServiceProviderSetUpWidget {
  const MvcApp({required this.child, this.serviceProvider, super.key, super.id, super.classes, super.attributes});
  @override
  final ServiceProvider? serviceProvider;
  final Widget child;
  @override
  Widget build(BuildContext context) => child;
}
