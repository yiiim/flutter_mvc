part of '../flutter_mvc.dart';

class _MvcDependencyProviderController extends MvcProxyController implements MvcServiceScopedBuilder {
  _MvcDependencyProviderController(this.provider);
  final void Function(MvcServiceCollection collection)? provider;
  @override
  void serviceScopedBuild(ServiceCollection collection) {
    provider?.call(collection as MvcServiceCollection);
  }
}

/// Mvc依赖提供者，可以使用[MvcDependencyProvider]为子级提供依赖
class MvcDependencyProvider extends StatelessWidget {
  const MvcDependencyProvider({required this.child, required this.provider, super.key});
  final void Function(MvcServiceCollection collection)? provider;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return MvcProxy(
      proxyCreate: () => _MvcDependencyProviderController(provider),
      child: child,
    );
  }
}
