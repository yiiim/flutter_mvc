# Login Example

In this example, we use flutter_mvc to create a simple login page.

![Login Example](../../login.gif)

## Project Setup

We will first create a brand new Flutter project
```bash
flutter create login
```

Next, install all dependencies.

Add `flutter_mvc` dependency in the `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_mvc: ^5.0.1
```

Then run `flutter pub get` to install the dependencies.

## Create App State

We will create an `AppState` class to manage the app's global state, including theme mode and login status.

```dart
class AppState {
  ThemeMode themeMode = ThemeMode.light;
  bool isLogin = false;
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
```

## Create Login Manager

We will create a `LoginManager` class to handle login logic.

```dart
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
    _stateScope.removeStateListener(this);
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
```

We use dependency injection to get the `MvcStateScope` instance. Since we inject `LoginManager` into the root dependency injection scope, when getting `MvcStateScope` through its dependency injection, we will get the root state scope. Also, since `AppState` is in the root state scope, we can use it to manage `AppState`.

## main

```dart
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
```

Inject `LoginManager` into the root dependency injection scope, and create `AppState` state when the root state scope is created.

`MaterialApp` uses `themeMode` and `navigatorKey` from `AppState`. This will cause `MaterialApp` to rebuild when `themeMode` or `navigatorKey` in `AppState` changes.

Then we use `Mvc` to create `LoginController`.

### Login Page

#### Login Page State
```dart
class LoginState {
  String username = '';
  String password = '';
  String? userNameErrorMessage;
  String? passwordErrorMessage;
  String? loginErrorMessage;
  bool loading = false;
  bool get isValid => userNameErrorMessage == null && passwordErrorMessage == null && username.isNotEmpty && password.isNotEmpty;
}
```

#### Login Controller

```dart
class LoginController extends MvcController with MvcStatefulService<LoginState> {
  void updateUsername(String username) {
    stateScope.setState(
      (LoginState state) {
        state.username = username;
        if (state.userNameErrorMessage != null) {
          state.userNameErrorMessage = validateUsername();
        }
      },
    );
  }

  void updatePassword(String password) {
    stateScope.setState(
      (LoginState state) {
        state.password = password;
        if (state.passwordErrorMessage != null) {
          state.passwordErrorMessage = validatePassword();
        }
      },
    );
  }

  String? validateUsername() {
    if (state.username.isEmpty) {
      return 'Username cannot be empty';
    }
    return null;
  }

  String? validatePassword() {
    if (state.password.isEmpty) {
      return 'Password cannot be empty';
    } else if (state.password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void login() async {
    final String? usernameError = validateUsername();
    final String? passwordError = validatePassword();
    if (usernameError != null || passwordError != null) {
      setState((LoginState state) {
        state.userNameErrorMessage = usernameError;
        state.passwordErrorMessage = passwordError;
      });
      return;
    }
    setState(
      (LoginState state) {
        state.loading = true;
      },
    );
    final loginResult = await getService<LoginManager>().login(state.username, state.password);
    setState(
      (LoginState state) {
        state.loading = false;
      },
    );
    if (!loginResult) {
      if (widgetScope.context.mounted) {
        ScaffoldMessenger.of(widgetScope.context).showSnackBar(
          const SnackBar(content: Text('Login failed. Invalid username or password.')),
        );
      }
    }
  }

  @override
  MvcView<MvcController> view() {
    return LoginView();
  }

  @override
  LoginState initializeState() {
    return LoginState();
  }
}
```

We use `MvcStatefulService` to manage the login page state `LoginState`. This mixin automatically uses the `MvcStateScope` from the current dependency injection scope to create and destroy the state, and provides the `setState` method to update the state.

The `LoginManager` instance is obtained through dependency injection to execute the login logic.

#### Login View

```dart
class LoginView extends MvcView<LoginController> {
  @override
  Widget buildView() {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ThemeSwitch(),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Login Page'),
                    ],
                  ),
                  const _UserNameInput(),
                  const _PasswordInput(),
                  const SizedBox(height: 16),
                  const _LoginButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

##### Theme Switch Widget

```dart
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.stateAccessor.useState(
      (AppState state) => state.themeMode,
    );
    return Row(
      children: [
        Text('Dark Mode:'),
        Switch(
          value: mode == ThemeMode.dark,
          onChanged: (bool value) {
            context.stateScope.setState(
              (AppState state) {
                state.themeMode = value ? ThemeMode.dark : ThemeMode.light;
              },
            );
          },
        ),
      ],
    );
  }
}
```

The theme switch widget uses `themeMode` from `AppState` to display the current theme mode and allows the user to toggle the theme mode. Since `AppState` is in the root state scope, this widget can access it. You can also update `themeMode` in `AppState` through `context.stateScope` in this widget.

##### Login Form Widgets

```dart
class _UserNameInput extends StatelessWidget {
  const _UserNameInput();

  @override
  Widget build(BuildContext context) {
    final controller = context.getService<LoginController>();
    final userNameErrorMessage = context.stateAccessor.useState(
      (LoginState state) => state.userNameErrorMessage,
    );
    return TextField(
      onChanged: (value) {
        controller.updateUsername(value);
      },
      decoration: InputDecoration(
        labelText: 'Username',
        hintText: 'Enter your username',
        errorText: userNameErrorMessage,
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  const _PasswordInput();

  @override
  Widget build(BuildContext context) {
    final controller = context.getService<LoginController>();
    final passwordErrorMessage = context.stateAccessor.useState(
      (LoginState state) => state.passwordErrorMessage,
    );
    return TextField(
      onChanged: (value) {
        controller.updatePassword(value);
      },
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        errorText: passwordErrorMessage,
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton();

  @override
  Widget build(BuildContext context) {
    final controller = context.getService<LoginController>();
    final (isValid, loading) = context.stateAccessor.useState(
      (LoginState state) => (state.isValid, state.loading),
    );
    return ElevatedButton(
      onPressed: isValid && !loading
          ? () {
              controller.login();
            }
          : null,
      child: loading ? const CircularProgressIndicator() : const Text('Login'),
    );
  }
}
```
Dependency injection is used to get the `LoginController` instance, and the state from `LoginState` is used to display error messages and control the login button's availability.

At this point, we have implemented a fairly complete login functionality. The full source code can be viewed [here](https://github.com/yiiim/flutter_mvc/tree/master/examples/login).
