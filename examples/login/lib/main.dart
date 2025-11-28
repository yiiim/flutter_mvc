import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:login/login/controller.dart';

class AppState {
  ThemeMode themeMode = ThemeMode.light;
  bool isLogin = false;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

class LoginManager with DependencyInjectionService implements MvcStateListener {
  late final MvcStateScope _stateScope = getService();

  void loginOut() {
    _stateScope.setState(
      (AppState state) {
        state.isLogin = false;
      },
    );
  }

  Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (username != 'admin' || password != 'password') {
      return false;
    }
    _stateScope.setState(
      (AppState state) {
        state.isLogin = true;
      },
    );
    return true;
  }

  @override
  FutureOr dependencyInjectionServiceInitialize() {
    _stateScope.listenState(this, (AppState state) => state.isLogin);
  }

  @override
  void dispose() {
    super.dispose();
    _stateScope.removeStateListener<AppState>(this);
  }

  @override
  void onMvcStateChanged(Object state) {
    assert(state is AppState);
    final appState = state as AppState;
    if (appState.isLogin) {
      appState.navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Home Page'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Welcome! You are logged in.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _stateScope.setState(
                        (AppState state) {
                          state.isLogin = false;
                        },
                      );
                    },
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      appState.navigatorKey.currentState!.pushReplacement(
        MaterialPageRoute(
          builder: (context) => Mvc(
            create: () => LoginController(),
          ),
        ),
      );
    }
  }
}

void main() {
  runApp(
    MvcApp(
      serviceProviderBuilder: (collection) {
        collection.addSingleton((_) => LoginManager());
      },
      onStateScopeCreated: (scope) {
        scope.createState(AppState());
      },
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final (themeMode, navigatorKey) = context.stateAccessor.useState(
          (AppState state) => (state.themeMode, state.navigatorKey),
        );
        return MaterialApp(
          themeMode: themeMode,
          darkTheme: ThemeData.dark(),
          navigatorKey: navigatorKey,
          home: Mvc(
            create: () => LoginController(),
          ),
        );
      },
    );
  }
}
