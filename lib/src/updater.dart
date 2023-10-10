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
