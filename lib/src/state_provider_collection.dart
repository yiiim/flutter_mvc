import 'package:flutter_mvc/src/flutter_mvc.dart';

class MvcStateProviderCollection extends MvcStateProvider {
  late final _collection = <MvcStateProvider>[];

  void addProvider(MvcStateProvider provider) {
    if (_collection.contains(provider)) {
      _collection.remove(provider);
    }
    _collection.insert(0, provider);
  }

  void removeProvider(MvcStateProvider provider) => _collection.remove(provider);

  @override
  MvcStateValue<T>? getStateValue<T>({Object? key}) {
    for (var element in _collection) {
      var value = element.getStateValue<T>(key: key);
      if (value != null) return value;
    }
    return null;
  }
}
