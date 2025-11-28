import 'package:flutter/material.dart';
import 'package:flutter_mvc/flutter_mvc.dart';
import 'package:login/login/controller.dart';
import 'package:login/main.dart';

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