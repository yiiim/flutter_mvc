import 'package:flutter_mvc/flutter_mvc.dart';

abstract class MvcWidgetUpdater {
  void update();
}

extension MvcWidgetUpdaterListExtension on List<MvcWidgetUpdater> {
  void update() {
    for (var updater in this) {
      updater.update();
    }
  }
}

extension MvcWidgetUpdaterIterableExtension on Iterable<MvcWidgetUpdater> {
  void update() {
    for (var updater in this) {
      updater.update();
    }
  }
}

class MvcWidgetQueryPredicate {
  MvcWidgetQueryPredicate({this.id, this.classes, this.type, this.typeString, this.serviceType});
  factory MvcWidgetQueryPredicate.makeWithServiceType(Type? serviceType) {
    return MvcWidgetQueryPredicate(serviceType: serviceType);
  }
  factory MvcWidgetQueryPredicate.makeWithWidgetType(Type? type) {
    return MvcWidgetQueryPredicate(type: type);
  }
  factory MvcWidgetQueryPredicate.makeWithQuery(String query) {
    String? id;
    String? classes;
    String? typeString;

    switch (query[0]) {
      case '#':
        id = query.substring(1);
        break;
      case '.':
        classes = query.substring(1);
        break;
      default:
        typeString = query;
        break;
    }
    return MvcWidgetQueryPredicate(id: id, classes: classes, typeString: typeString);
  }
  final String? id;
  final String? classes;
  final String? typeString;
  final Type? type;
  final Type? serviceType;
}

class MvcWidgetManager implements MvcWidgetUpdater {
  MvcWidgetManager(this.element, {this.blocker = false});
  final MvcWidgetElement element;
  final bool blocker;
  late final List<MvcWidgetManager> _children = [];
  MvcWidgetManager? _parent;

  void mount({MvcWidgetManager? parent}) {
    _parent = parent;
    _parent?._children.add(this);
  }

  void activate({MvcWidgetManager? newParent}) {
    _parent = newParent;
    _parent?._children.add(this);
  }

  void deactivate() {
    _parent?._children.remove(this);
  }

  void unmount() {
    _parent?._children.remove(this);
  }

  bool isMatch(MvcWidgetQueryPredicate predicate) {
    if (predicate.id != null) {
      if (element.widget.id == predicate.id) {
        return true;
      }
    }
    if (predicate.classes != null) {
      if (element.widget.classes?.contains(predicate.classes) == true) {
        return true;
      }
    }
    if (predicate.type != null) {
      if (element.widget.runtimeType == predicate.type) {
        return true;
      }
    }
    if (predicate.typeString != null) {
      if (element.widget.runtimeType.toString() == predicate.typeString) {
        return true;
      }
    }
    return false;
  }

  Iterable<MvcWidgetUpdater> query(MvcWidgetQueryPredicate predicate) sync* {
    for (var item in _children) {
      if (item.isMatch(predicate)) {
        yield item;
        if (predicate.id != null) return;
      }
      if (!item.blocker) yield* item.query(predicate);
    }
  }

  @override
  void update() {
    element.markNeedsBuild();
  }
}
