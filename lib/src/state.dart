part of './flutter_mvc.dart';

abstract class MvcState<TControllerType extends MvcController> {
  BuildContext get context;
  TControllerType get controller;

  T? get<T>({Object? key});
  MvcStateValue<T>? getValue<T>({Object? key});
}

class MvcStateKey {
  MvcStateKey({required this.stateType, this.key});
  final Type stateType;
  final Object? key;

  @override
  int get hashCode => Object.hashAll([stateType, key]);

  @override
  bool operator ==(Object other) {
    return other is MvcStateKey && stateType == other.stateType && other.key == key;
  }
}

class MvcStateValue<T> extends ValueNotifier<T> {
  MvcStateValue(super.value, {required this.controller, this.global = false, this.forChild = true});
  final MvcController controller;
  final bool global;
  final bool forChild;
  void update() => notifyListeners();
}

class MvcStateValueTransformer<T, E> extends MvcStateValue<T> {
  MvcStateValueTransformer(super.value, this._source, this._transformer, {required super.controller, super.global, super.forChild}) : super() {
    _source.addListener(_transformListener);
  }
  void _transformListener() async {
    var transformValue = _transformer(_source.value);
    if (transformValue is Future) {
      Future(
        () async {
          var newValue = await transformValue;
          if(newValue == value){
            notifyListeners();
          }
          value = newValue;
        },
      );
    } else {
      if (value == transformValue) {
        notifyListeners();
      }
      value = transformValue;
    }
  }

  final MvcStateValue<E> _source;
  final FutureOr<T> Function(E state) _transformer;
  @override
  void dispose() {
    _source.removeListener(_transformListener);
    super.dispose();
  }
}
