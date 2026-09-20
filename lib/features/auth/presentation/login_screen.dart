import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository repository;

  const LoginScreen({super.key, required this.repository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.repository.login(_email.text.trim(), _password.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/catalog');
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Iniciar sesión')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AppTextField(
                label: 'Correo',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value != null && value.contains('@') ? null : 'Correo inválido',
              ),
              AppTextField(
                label: 'Contraseña',
                controller: _password,
                obscureText: true,
                validator: (value) =>
                    value != null && value.length >= 8 ? null : 'Mínimo 8 caracteres',
              ),
              if (_error != null)
                AppBanner(message: _error!, tone: AppBannerTone.error),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Ingresar',
                onPressed: _loading ? null : _submit,
                loading: _loading,
                expanded: true,
              ),
            ],
          ),
        ),
      );
}
