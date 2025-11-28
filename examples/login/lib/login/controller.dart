import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:login/main.dart';

import 'view.dart';

class LoginState {
  String username = '';
  String password = '';
  String? userNameErrorMessage;
  String? passwordErrorMessage;
  String? loginErrorMessage;
  bool loading = false;
  bool get isValid => userNameErrorMessage == null && passwordErrorMessage == null && username.isNotEmpty && password.isNotEmpty;
}

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
