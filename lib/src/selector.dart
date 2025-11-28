import 'package:flutter/material.dart';
import 'package:flutter_mvc/src/framework.dart';

/// Extension methods for collections of [MvcWidgetScope].
extension MvcWidgetScopeCollection on Iterable<MvcWidgetScope> {
  /// Triggers an update for all widgets in the collection.
  ///
  /// If [fn] is provided, it is called once before the updates are triggered.
  /// This is useful for batching state changes before a rebuild.
  ///
  /// ```dart
  /// // Find all widgets with the '.item' class and update their state.
  /// querySelectorAll('.item').update(() {
  ///   // state changes
  /// });
  /// ```
  void update([void Function()? fn]) {
    fn?.call();
    for (var updater in this) {
      updater.update();
    }
  }

  /// Finds all descendant [MvcWidget]s of the widgets in this collection that match the given [selectors].
  ///
  /// This performs a `querySelectorAll` on each widget in the current collection
  /// and returns a new collection containing all the results.
  Iterable<MvcWidgetScope> querySelectorAll<T>([String? selectors]) {
    return expand((e) => e.querySelectorAll<T>(selectors));
  }

  /// Finds the first descendant [MvcWidget] in this collection that matches the given [selectors].
  ///
  /// It iterates through the widgets in the current collection and returns the first
  /// match found by `querySelector`.
  MvcWidgetScope? querySelector<T>([String? selectors]) {
    for (var updater in this) {
      var result = updater.querySelector<T>(selectors);
      if (result != null) return result;
    }
    return null;
  }
}

/// An interface for an object that can query for [MvcWidget]s using selectors.
abstract class MvcWidgetSelector {
  /// Finds all descendant [MvcWidget]s that match the given [selectors].
  ///
  /// You can use a querySelectorAll-like syntax from the W3C standard to query Widgets.
  /// Sibling lookups are not supported.
  ///
  /// When you provide a type [T], it is used as a type selector, equivalent to
  /// prepending the type name to the [selectors] string.
  ///
  /// [ignoreSelectorBreaker] allows the query to bypass widgets that would normally
  /// stop selector propagation (i.e., where `isSelectorBreaker` is true).
  ///
  /// Example:
  /// ```dart
  /// // Find all MyItemWidget widgets with the class 'highlight'
  /// context.querySelectorAll<MyItemWidget>('.highlight');
  /// ```
  Iterable<MvcWidgetScope> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]);

  /// Finds the first descendant [MvcWidget] that matches the given [selectors].
  ///
  /// See [querySelectorAll] for more details on selectors.
  MvcWidgetScope? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]);
}

class MvcSelectorBreaker extends MvcStatefulWidget {
  const MvcSelectorBreaker({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  MvcWidgetState<MvcSelectorBreaker> createState() => _MvcSelectorBreakerState();
}

class _MvcSelectorBreakerState extends MvcWidgetState<MvcSelectorBreaker> {
  @override
  bool get isSelectorBreaker => true;

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
