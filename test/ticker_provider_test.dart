import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ticker Provider Mixins', () {
    testWidgets('MvcSingleTickerProviderStateMixin provides ticker', (tester) async {
      await tester.pumpWidget(
        const MvcApp(
          child: MaterialApp(
            home: Mvc<_SingleTickerController, void>(
              create: _SingleTickerController.new,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final controller = context.getMvcService<_SingleTickerController>();

      // Controller can create animation controller
      final animController = AnimationController(
        vsync: controller,
        duration: const Duration(seconds: 1),
      );

      expect(animController, isNotNull);
      expect(animController.duration, equals(const Duration(seconds: 1)));

      animController.dispose();
    });

    testWidgets('MvcTickerProviderStateMixin provides multiple tickers', (tester) async {
      await tester.pumpWidget(
        const MvcApp(
          child: MaterialApp(
            home: Mvc<_MultiTickerController, void>(
              create: _MultiTickerController.new,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold));
      final controller = context.getMvcService<_MultiTickerController>();

      // Controller can create multiple animation controllers
      final animController1 = AnimationController(
        vsync: controller,
        duration: const Duration(milliseconds: 500),
      );

      final animController2 = AnimationController(
        vsync: controller,
        duration: const Duration(milliseconds: 300),
      );

      expect(animController1, isNotNull);
      expect(animController2, isNotNull);
      expect(animController1, isNot(same(animController2)));

      animController1.dispose();
      animController2.dispose();
    });

    testWidgets('ticker provider works with animations', (tester) async {
      await tester.pumpWidget(
        const MvcApp(
          child: MaterialApp(
            home: Mvc<_AnimationController, void>(
              create: _AnimationController.new,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Animation: 0.0'), findsOneWidget);

      final context = tester.element(find.byType(Scaffold));
      final controller = context.getMvcService<_AnimationController>();

      // Start animation
      controller.startAnimation();

      // Pump one frame to start animation
      await tester.pump();
      // Pump animation to midpoint
      await tester.pump(const Duration(milliseconds: 500));

      // Animation should be at or past midpoint
      expect(controller.animationValue >= 0.4, isTrue, reason: 'Animation value: ${controller.animationValue}');
      expect(controller.animationValue <= 0.6, isTrue, reason: 'Animation value: ${controller.animationValue}');
    });
  });
}

// Test Controllers
class _SingleTickerController extends MvcController<void> with MvcSingleTickerProviderStateMixin {
  @override
  MvcView view() => _EmptyView();
}

class _MultiTickerController extends MvcController<void> with MvcTickerProviderStateMixin {
  @override
  MvcView view() => _EmptyView();
}

class _AnimationController extends MvcController<void> with MvcSingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;

  double get animationValue => _animation.value;

  @override
  void init() {
    super.init();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animController);
  }

  void startAnimation() {
    _animController.forward();
  }

  @override
  MvcView view() => _AnimationView();

  @override
  void deactivate() {
    _animController.dispose();
    super.deactivate();
  }
}

class _EmptyView extends MvcView {
  @override
  Widget buildView() {
    return const Scaffold(
      body: Text('Empty'),
    );
  }
}

class _AnimationView extends MvcView<_AnimationController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller._animation,
        builder: (context, child) {
          return Text('Animation: ${controller.animationValue}');
        },
      ),
    );
  }
}
