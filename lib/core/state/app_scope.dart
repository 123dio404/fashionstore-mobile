import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Expone el [AppState] a todo el árbol y reconstruye al notificar.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Depende del estado: el llamador se reconstruye con cada cambio.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }

  /// Lee el estado sin suscribirse a cambios.
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol de widgets');
    return scope!.notifier!;
  }
}
