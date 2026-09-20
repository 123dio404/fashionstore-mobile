import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/widgets.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

class RegisterScreen extends StatefulWidget {
  final AuthRepository repository;
  const RegisterScreen({super.key, required this.repository});
  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      name = TextEditingController(),
      pass = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await widget.repository.register(RegisterRequest(
          email: email.text.trim(),
          fullName: name.text.trim(),
          password: pass.text));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Form(
          key: form,
          child: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
            AppTextField(
                label: 'Nombre completo',
                controller: name,
                validator: (v) =>
                    v != null && v.length > 1 ? null : 'Ingresa tu nombre'),
            AppTextField(
                label: 'Correo',
                controller: email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Correo inválido'),
            AppTextField(
                label: 'Contraseña',
                controller: pass,
                obscureText: true,
                validator: (v) =>
                    v != null && v.length >= 8 ? null : 'Mínimo 8 caracteres'),
            if (error != null)
              AppBanner(message: error!, tone: AppBannerTone.error),
            const SizedBox(height: AppSpacing.md),
            AppButton(
                label: 'Registrarme',
                onPressed: loading ? null : submit,
                loading: loading,
                expanded: true)
          ])));
}
