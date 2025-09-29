import 'package:flutter_mvc/src/framework.dart';

extension MvcWidgetUpdaterCollection on Iterable<MvcWidgetUpdater> {
  void update([void Function()? fn]) {
    fn?.call();
    for (var updater in this) {
      updater.update();
    }
  }

  Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors]) {
    return expand((e) => e.querySelectorAll<T>(selectors));
  }

  MvcWidgetUpdater? querySelector<T>([String? selectors]) {
    for (var updater in this) {
      var result = updater.querySelector<T>(selectors);
      if (result != null) return result;
    }
    return null;
  }
}

abstract class MvcWidgetUpdater extends MvcWidgetSelector {
  void update([void Function()? fn]);

  MvcContext get context;
}

abstract class MvcWidgetSelector {
  /// You can use a querySelectorAll-like syntax from the W3C standard to query Widgets,
  /// but sibling lookups are not supported. When you provide [T],
  /// the type [T] will be inserted at the beginning of [selectors] as the localName.
  Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]);

  /// See [querySelectorAll]
  MvcWidgetUpdater? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]);
}
