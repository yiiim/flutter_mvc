part of './flutter_mvc.dart';

class MvcWidgetManager {
  late final Map<Type, List<MvcWidgetElement>> _typedWidgets = {};
  late final Map<Key, List<MvcWidgetElement>> _keyedWidgets = {};
  late final List<MvcWidgetManager> _children = [];
  void _registerWidget(MvcWidgetElement element) {
    _typedWidgets[element.widget.runtimeType] ??= [];
    _typedWidgets[element.widget.runtimeType]!.add(element);
    if (element.widget.key != null) {
      _keyedWidgets[element.widget.key!] ??= [];
      _keyedWidgets[element.widget.key!]!.add(element);
    }
  }

  void _updateWidget(Widget oldWidget, MvcWidgetElement element) {
    assert(_typedWidgets[oldWidget.runtimeType] != null);

    if (oldWidget.runtimeType != element.runtimeType) {
      _typedWidgets[oldWidget.runtimeType]!.remove(element);
      _typedWidgets[element.widget.runtimeType] ??= [];
      _typedWidgets[element.widget.runtimeType]!.add(element);
      if (_typedWidgets[oldWidget.runtimeType]!.isEmpty) {
        _typedWidgets.remove(oldWidget.runtimeType);
      }
    }

    if (oldWidget.key != element.widget.key) {
      if (element.widget.key != null) {
        _keyedWidgets[element.widget.key!] ??= [];
        _keyedWidgets[element.widget.key!]!.add(element);
      }
      if (oldWidget.key != null) {
        assert(_keyedWidgets[oldWidget.key] != null);
        _keyedWidgets[oldWidget.key]!.remove(element);
        if (_keyedWidgets[oldWidget.key]!.isEmpty) {
          _keyedWidgets.remove(oldWidget.key);
        }
      }
    }
  }

  void _registerChild(MvcWidgetManager child) => _children.add(child);

  void update<T extends Widget>({bool deep = false}) {
    for (var element in _typedWidgets[T] ?? <MvcWidgetElement>[]) {
      element.markNeedsBuild();
    }
    if (deep) {
      for (var element in _children) {
        element.update<T>();
      }
    }
  }

  void updateWithKey(Key key, {bool deep = false}) {
    for (var element in _keyedWidgets[key] ?? <MvcWidgetElement>[]) {
      element.markNeedsBuild();
    }
    if (deep) {
      for (var element in _children) {
        element.updateWithKey(key, deep: true);
      }
    }
  }
}
