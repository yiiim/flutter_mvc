import 'package:flutter/material.dart';

import 'context.dart';
import 'framework.dart';
import 'mvc.dart';

/// use [MvcController.$] to update it in controller
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
///     $("#title").update(() => title = "new title");  // update with id
///   }
///   void updateTitleWithClasses() {
///     $(".title").update(() => title = "new title");  // update with classes
///   }
/// }
/// ```
class MvcBuilder<TControllerType extends MvcController> extends MvcStatelessWidget<TControllerType> {
  const MvcBuilder({super.key, super.classes, super.id, required this.builder});
  final Widget Function(MvcContext<TControllerType> context) builder;
  @override
  Widget build(BuildContext context) {
    return builder(context as MvcContext<TControllerType>);
  }
}

/// use [MvcController.$] to update it in controller
/// 
/// example:
/// ```dart
/// class TestController extends MvcController {
///   String title = "title";
///   void updateHeader() {
///     $<MvcHeader>().update();  
///   }
/// }
/// ```
class MvcHeader extends MvcBuilder {
  const MvcHeader({required super.builder, super.id, super.classes, super.key});
}

/// use [MvcController.$] to update it in controller
/// 
/// example:
/// ```dart
/// class TestController extends MvcController {
///   String title = "title";
///   void updateBody() {
///     $<MvcBody>().update();  
///   }
/// }
/// ```
class MvcBody extends MvcBuilder {
  const MvcBody({required super.builder, super.id, super.classes, super.key});
}

/// use [MvcController.$] to update it in controller
/// 
/// example:
/// ```dart
/// class TestController extends MvcController {
///   String title = "title";
///   void updateFooter() {
///     $<MvcFooter>().update();  
///   }
/// }
/// ```
class MvcFooter extends MvcBuilder {
  const MvcFooter({required super.builder, super.id, super.classes, super.key});
}
