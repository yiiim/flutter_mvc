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

class MvcWidgetQueryPredicate {
  MvcWidgetQueryPredicate({this.id, this.classes, this.type, this.typeString});
  factory MvcWidgetQueryPredicate.make(String query, {Type? type}) {
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
    return MvcWidgetQueryPredicate(id: id, classes: classes, typeString: typeString, type: type);
  }
  final String? id;
  final String? classes;
  final String? typeString;
  final Type? type;
}

class MvcWidgetManager implements MvcWidgetUpdater {
  MvcWidgetManager(this.element);
  MvcWidgetElement element;
  MvcWidgetManager? _parent;
  late final List<MvcWidgetManager> _children = [];

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

  List<MvcWidgetManager> _query(MvcWidgetQueryPredicate predicate) {
    List<MvcWidgetManager> result = [];
    for (var item in _children) {
      result.addAll(item._query(predicate));
      if (predicate.id != null) {
        if (item.element.widget.id == predicate.id) {
          result.add(item);
          continue;
        }
      }
      if (predicate.classes != null) {
        if (item.element.widget.classes?.contains(predicate.classes) == true) {
          result.add(item);
          continue;
        }
      }
      if (predicate.type != null) {
        if (item.element.widget.runtimeType == predicate.type) {
          result.add(item);
          continue;
        }
      }
    }
    return result;
  }

  List<MvcWidgetUpdater> query(MvcWidgetQueryPredicate predicate) => _query(predicate);

  @override
  void update() {
    element.markNeedsBuild();
  }
}
