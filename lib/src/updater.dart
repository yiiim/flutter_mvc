abstract class MvcWidgetUpdater {
  void update();
}

extension MvcWidgetUpdaterListExtension on List<MvcWidgetUpdater> {
  void update([void Function()? fn]) {
    fn?.call();
    for (var updater in this) {
      updater.update();
    }
  }
}

extension MvcWidgetUpdaterIterableExtension on Iterable<MvcWidgetUpdater> {
  void update([void Function()? fn]) {
    fn?.call();
    for (var item in this) {
      item.update();
    }
  }
}

class MvcUpdaterQueryPredicate {
  MvcUpdaterQueryPredicate({this.id, this.classes, this.type, this.typeString, this.serviceType});
  factory MvcUpdaterQueryPredicate.makeWithServiceType(Type? serviceType) {
    return MvcUpdaterQueryPredicate(serviceType: serviceType);
  }
  factory MvcUpdaterQueryPredicate.makeWithWidgetType(Type? type) {
    return MvcUpdaterQueryPredicate(type: type);
  }
  factory MvcUpdaterQueryPredicate.makeWithQuery(String query) {
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
    return MvcUpdaterQueryPredicate(id: id, classes: classes, typeString: typeString);
  }
  final String? id;
  final String? classes;
  final String? typeString;
  final Type? type;
  final Type? serviceType;
}
