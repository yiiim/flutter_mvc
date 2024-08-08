import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'query_selector.dart' as query_selector;

String _typeLocalName(Type type) {
  final result = type.toString().replaceAll(RegExp(r'<[\s\S]+>$'), "").toLowerCase();
  if (kIsWeb) {
    return result.replaceFirst(":", "");
  }
  return result;
}

abstract class MvcNode implements MvcWidgetUpdater, MvcWidgetSelector {
  String get id;
  MvcNode? get parent;
  String get localName;
  List<String> get classes;
  String? get namespaceUri;
  List<MvcNode> get children;
  Map<Object, String> get attributes;
  MvcNode? get nextElementSibling;
  MvcNode? get previousElementSibling;
  bool get isSelectorBreaker;

  @override
  Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]) {
    final result = query_selector.querySelectorAll(
      this,
      "${T != dynamic ? _typeLocalName(T) : ""}${selectors ?? ""}",
      ignoreSelectorBreaker: ignoreSelectorBreaker,
    );
    return result;
  }

  @override
  MvcWidgetUpdater? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]) {
    return query_selector.querySelector(
      this,
      "${T != dynamic ? _typeLocalName(T) : ""}${selectors ?? ""}",
      ignoreSelectorBreaker: ignoreSelectorBreaker,
    );
  }
}

class MvcElementNode extends MvcNode {
  MvcElementNode(this.element);
  final MvcNodeMixin element;
  @override
  bool get isSelectorBreaker => element.isSelectorBreaker;

  @override
  Map<Object, String> get attributes {
    if (element.widget is MvcWidget) {
      return (element.widget as MvcWidget).attributes ?? {};
    }
    return {};
  }

  @override
  List<MvcNode> get children => element._childrenElements.map((e) => e._mvcNode).toList();

  @override
  List<String> get classes {
    if (element.widget is MvcWidget) {
      return (element.widget as MvcWidget).classes ?? [];
    }
    return [];
  }

  @override
  String get id => element.widget is MvcWidget ? (element.widget as MvcWidget).id ?? "" : "";

  @override
  String get localName => _typeLocalName(element.widget.runtimeType);

  @override
  String? get namespaceUri => null;

  @override
  MvcNode? get nextElementSibling => null;

  @override
  MvcNode? get parent => element._parentElement?._mvcNode;

  @override
  MvcNode? get previousElementSibling => null;

  @override
  void update([void Function()? fn]) {
    fn?.call();
    element.markNeedsBuild();
  }

  @override
  MvcContext get context => element as MvcContext;
}

class MvcImplicitRootNode extends MvcNode {
  static MvcImplicitRootNode instance = MvcImplicitRootNode();
  final List<MvcNodeMixin> elements = [];

  @override
  Map<Object, String> get attributes => {};
  @override
  List<MvcNode> get children => elements.map((e) => e._mvcNode).toList();
  @override
  List<String> get classes => [];
  @override
  String get id => "";
  @override
  String get localName => "";
  @override
  String? get namespaceUri => null;
  @override
  MvcNode? get nextElementSibling => null;
  @override
  MvcNode? get parent => null;
  @override
  MvcNode? get previousElementSibling => null;

  @override
  void update([void Function()? fn]) {
    fn?.call();
    for (var element in elements) {
      element.markNeedsBuild();
    }
  }

  @override
  bool get isSelectorBreaker => false;

  @override
  MvcContext get context => throw UnimplementedError();
}

mixin MvcNodeMixin on MvcBasicElement implements MvcWidgetSelector {
  MvcNodeMixin? _parentElement;
  final List<MvcNodeMixin> _childrenElements = [];
  late final MvcElementNode _mvcNode = MvcElementNode(this);

  @visibleForTesting
  MvcWidgetUpdater get debugUpdater => _mvcNode;

  /// Whether to allow queries from superiors to continue looking for children
  bool get isSelectorBreaker => false;

  @override
  void mount(Element? parent, Object? newSlot) {
    _parentElement = parent?.tryGetMvcService<MvcNodeMixin>();
    _parentElement?._childrenElements.add(this);
    if (_parentElement == null) {
      MvcImplicitRootNode.instance.elements.add(this);
    }
    super.mount(parent, newSlot);
  }

  @override
  void activate() {
    super.activate();
    visitAncestorElements(
      (element) {
        _parentElement = element.tryGetMvcService<MvcNodeMixin>();
        _parentElement?._childrenElements.add(this);
        return false;
      },
    );
    if (_parentElement == null) {
      MvcImplicitRootNode.instance.elements.add(this);
    }
  }

  @override
  void deactivate() {
    super.deactivate();
    if (_parentElement == null) {
      MvcImplicitRootNode.instance.elements.remove(this);
    }
    _parentElement?._childrenElements.remove(this);
    _parentElement = null;
  }

  @override
  void initServices(ServiceCollection collection, ServiceProvider? parent) {
    super.initServices(collection, parent);
    collection.add<MvcNodeMixin>((serviceProvider) => this);
  }

  @override
  Iterable<MvcWidgetUpdater> querySelectorAll<T>([String? selectors, bool ignoreSelectorBreaker = false]) => _mvcNode.querySelectorAll<T>(
        selectors,
        ignoreSelectorBreaker,
      );

  @override
  MvcWidgetUpdater? querySelector<T>([String? selectors, bool ignoreSelectorBreaker = false]) => _mvcNode.querySelector<T>(
        selectors,
        ignoreSelectorBreaker,
      );
}
