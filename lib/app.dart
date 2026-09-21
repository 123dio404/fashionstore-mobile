import 'package:flutter/material.dart';

import 'core/models/fashion_models.dart';
import 'core/state/app_scope.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/app_shell.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';

/// Raíz de la app: máquina de estados splash → onboarding → auth → shell.
class FashionStoreApp extends StatefulWidget {
  const FashionStoreApp({super.key, required this.auth});

  final AuthRepository auth;

  @override
  State<FashionStoreApp> createState() => _FashionStoreAppState();
}

class _FashionStoreAppState extends State<FashionStoreApp> {
  final AppState _state = AppState();

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'FashionStore',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) {
            final s = AppScope.of(context);
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _screen(s),
            );
          },
        ),
      ),
    );
  }

  Widget _screen(AppState s) {
    switch (s.phase) {
      case AppPhase.splash:
        return SplashScreen(
          key: const ValueKey('splash'),
          onDone: () => s.goTo(AppPhase.onboarding),
        );
      case AppPhase.onboarding:
        return OnboardingScreen(
          key: const ValueKey('onboarding'),
          onDone: () => s.goTo(AppPhase.login),
        );
      case AppPhase.login:
        return LoginScreen(
          key: const ValueKey('login'),
          auth: widget.auth,
          onSuccess: () => s.goTo(AppPhase.app),
          onGoRegister: () => s.goTo(AppPhase.register),
        );
      case AppPhase.register:
        return RegisterScreen(
          key: const ValueKey('register'),
          auth: widget.auth,
          onSuccess: () => s.goTo(AppPhase.app),
          onGoLogin: () => s.goTo(AppPhase.login),
        );
      case AppPhase.app:
        return const AppShell(key: ValueKey('shell'));
    }
  }
}
