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