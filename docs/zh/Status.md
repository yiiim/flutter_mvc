
# 状态管理

在Mvc中，状态的类型为```MvcStateValue<T>```

```dart
class MvcStateValue<T> extends ChangeNotifier {
  MvcStateValue(this.value);
  T value;

  void update() => notifyListeners();
}
```

它是一个类似于```ValueNotifier```的类，不过并不会在每次setValue的发送通知，仅会在调用```update()```方法时发送。这里可以理解为**每次```update()```时触发状态更新**。

## 更新Widget

使用状态更新Widget，需要使用到一个```MvcStateScope```的```Widget```，它的定义如下所示：

```dart
class MvcStateScope<TControllerType extends MvcController> extends Widget {
  const MvcStateScope(this.builder, {this.stateProvider, this.child, Key? key}) : super(key: key);

  final Widget Function(MvcWidgetStateProvider state) builder;

  final MvcStateProvider? stateProvider;

  final Widget? child;
}
```

**builder** 状态更新时重建的builder

**stateProvider** 状态提供者，通常为```MvcController```，如果为空，则状态提供者为离```MvcStateScope```最近的类型为泛型```TControllerType```的```MvcController```

**child** 在状态更新时，如果有不需要更新的Widget，通过这个参数传递，可以通过```builder```方法中的参数获取，用于节省性能

使用方式：

```dart
MvcStateScope<IndexPageController>(
    (MvcWidgetStateProvider state) {
        return Text("${state.get<int>()}");
    },
)
```

在builder方法中的参数```MvcWidgetStateProvider```可以**获取状态提供者提供的全部状态**，并且一旦**通过它获取过的状态更新时，Widget就会更新**。

状态提供者```MvcStateProvider```的定义如下：

```dart
abstract class MvcStateProvider {
  T? getState<T>({Object? key});

  MvcStateValue<T>? getStateValue<T>({Object? key});
}
```

它是一个抽象接口，尽管你可以自己实现它为```MvcStateScope```提供状态，但是在Mvc中```MvcController```实现了该接口。状态相关的操作均在```MvcController```中进行。

## 初始化状态

方法定义

```dart
MvcStateValue<T> initState<T>(T state, {Object? key, MvcStateAccessibility accessibility = MvcStateAccessibility.public})
```

使用示例

```dart
initState<int>(0)
```

在Controller中任何时候都可以使用```initState```来初始化一个新的状态，状态将会保存在Controller中直至Controller销毁。

**key** 状态标识，**在同一个Controller中状态依靠泛型类型以及```key```的hashCode来区分唯一性**

**accessibility** 状态的访问级别：

```dart
enum MvcStateAccessibility {
  /// 全局的
  global,

  /// 公开的
  public,

  /// 私有的
  private,

  /// 内部的
  internal,
}
```

* global，任何Controller都可以获取到该状态
* public，当前Controller以及他的子级可以获取到该状态，默认为public
* private，当前Controller以及的ControllerPart可以获取到该状态
* internal，只有状态创建者才可以获取该状态

在一个Controller实例中同一个状态只能初始化一次，泛型类型和key的hashCode相同即表示同一个状态。

## 获取状态

可以在Controller中获取状态，方法为：

```dart
T? getState<T>({Object? key, bool onlySelf = false});
```

使用示例

```dart
var state = getState<int>()
```

获取状态时，根据初始化状态时的Key和状态类型来查找状态。查找状态不仅会查找当前Controller初始化的状态，还会依次查找父级中访问级别为```public```以上的状态，如果查找到最顶级还没有找到，则会查找当前所有Controller中访问级别为```global```的状态。简单的说就是可以获取到当前全部可访问的状态。

在使用```MvcStateScope```获取状态时，也是从```MvcStateProvider```获取，```MvcWidgetStateProvider```只是对```MvcStateProvider```的简单包装。

如果状态不存在则会返回null，但是如果状态本身为null，你可以使用```getStateValue```方法来获取返回的```MvcStateValue```，如果```MvcStateValue```为null则表示没有获取到该状态，如果```MvcStateValue```不为null，则它的value属性就是状态值

## 更新状态

```dart
MvcStateValue<T>? updateState<T>({void Function(MvcStateValue<T> state)? updater, Object? key})
```

使用示例

```dart
updateState<int>(updater:(state)=>state.value++);
```

**updater** 在改方法中可以将状态设置为新的值，不过即使不设置，也会触发状态更新

**key** 和获取状态一样，需要更新的状态的标识

同样需要在Controller中调用，如果没有获取到要更新的状态则返回null，仅可更新自己创建的状态。

## 删除状态

```dart
void deleteState<T>({Object? key});
```

同样在Controller中调用，仅可删除自己创建的状态。

## StatePart

在使用Key和类型作为状态的唯一标识时，可能需要创建很多的Key，造成代码的混乱不堪，为了减轻这种状况，提供了一个具有Part的状态提供接口

```dart
abstract class MvcHasPartStateProvider extends MvcStateProvider {
  T? getStatePart<T extends MvcStateProvider>();
}
```

这个接口可以根据类型返回另一个```Part```状态提供者。

在```MvcController```的实现中，返回的每个```Part```状态提供者中都使用了独立的状态，也就是说每个```Part```中都可以初始化同样类型同样Key的状态。但是在```Part```中只能初始化访问级别为```internal```的状态，```internal```的状态只能通过其自身获取，所以在获取```Part```中的状态时，需要先获取该```Part```然后再获取状态，在```MvcController```获取```Part```时，将会从自己开始往父级查找，直到找到指定类型的```Part```。获取```Part```中的状态的方法定义为：

```dart
getStatePart<TPartType>().getState<TStateType>(key:key)
```

使用方式：

```dart
indexPageController.getStatePart<IndexPageControllerBannerPart>().getState<int>(key:IndexPageControllerBannerPartKeys.bannerIndex)
```

它会从当前Controller开始往父级查找类型为```TPartType```，然后使用```TPartType```获取状态。如果```TPartType```中没有找到状态，则再交给```TPartType```所属的```MvcController```去获取

在```MvcStateScope```中使用：

```dart
state.part<IndexPageControllerBannerPart>().get<int>(key:IndexPageControllerBannerPartKeys.bannerIndex)
```

在```MvcStateScope```中使用时，仅当```MvcStateScope```所使用的```MvcStateProvider```是```MvcHasPartStateProvider```时才有效，否则返回null。在上面代码```part```是对```getStatePart```的包装，```get```是对```getState```的包装。

```MvcController```实现的```Part```类型为```MvcControllerPart```，有关```MvcControllerPart```的创建与使用可以阅读此处[MvcControllerPart](./Mvc/#MvcControllerPart)

## Model状态

在Controller中可以直接使用model属性获取Model，Model也是一个状态，也可以使用获取状态的方式获取（key为null），当Controller所属的Mvc被外部重建时Model状态将会更新

获取model状态：

```dart
var model = getState<TModelType>();
```

在```MvcStateScope```中获取：

## 状态总结

Controller主要职责就是处理逻辑，管理状态。

在Controller中无需处理UI相关的事情，只需要管理好状态，然后交由View使用，View只需要使用状态绘制UI的。状态的可访问级别可以让Controller中的状态可以被更多的想要获取的UI组件获取。Controller无需理会谁会获取状态，只需要管理谁可以获取状态即可。同样，View也无需理会谁来提供这个状态，只需要使用即可。


