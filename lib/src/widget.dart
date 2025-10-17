import 'package:flutter_mvc/flutter_mvc.dart';

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
class MvcHeader extends MvcWidgetScopeBuilder {
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
class MvcBody extends MvcWidgetScopeBuilder {
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
class MvcFooter extends MvcWidgetScopeBuilder {
  const MvcFooter({required super.builder, super.id, super.classes, super.attributes, super.key});
}
