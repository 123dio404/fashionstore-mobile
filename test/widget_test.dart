import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:fashionstore_mobile/features/auth/data/auth_repository.dart';
import 'package:fashionstore_mobile/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('login screen renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(repository: AuthRepository())),
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
