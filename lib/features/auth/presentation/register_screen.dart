import 'package:flutter/material.dart';
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
          child: ListView(padding: const EdgeInsets.all(24), children: [
            TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) =>
                    v != null && v.length > 1 ? null : 'Ingresa tu nombre'),
            TextFormField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Correo'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Correo inválido'),
            TextFormField(
                controller: pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) =>
                    v != null && v.length >= 8 ? null : 'Mínimo 8 caracteres'),
            if (error != null)
              Text(error!,
                  style: TextStyle(color: Theme.of(c).colorScheme.error)),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: loading ? null : submit,
                child: Text(loading ? 'Creando...' : 'Registrarme'))
          ])));
}
