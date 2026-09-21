import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/inputs.dart';
import '../data/auth_repository.dart';

/// Login del prototipo, conectado al backend real (`/auth/login`).
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.auth,
    required this.onSuccess,
    required this.onGoRegister,
  });

  final AuthRepository auth;
  final VoidCallback onSuccess;
  final VoidCallback onGoRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String? _emailErr;
  String? _passErr;
  String? _generalErr;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    String? e;
    String? p;
    final email = _email.text.trim();
    if (email.isEmpty) {
      e = 'El correo es obligatorio';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      e = 'Correo inválido';
    }
    if (_password.text.isEmpty) {
      p = 'La contraseña es obligatoria';
    } else if (_password.text.length < 6) {
      p = 'Mínimo 6 caracteres';
    }
    setState(() {
      _emailErr = e;
      _passErr = p;
      _generalErr = null;
    });
    return e == null && p == null;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      await widget.auth.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      widget.onSuccess();
    } catch (err) {
      if (!mounted) return;
      setState(() => _generalErr = _describe(err));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _describe(Object err) {
    if (err is DioException) {
      final data = err.response?.data;
      if (data is Map && data['detail'] != null) return '${data['detail']}';
      if (err.type == DioExceptionType.connectionError ||
          err.type == DioExceptionType.connectionTimeout) {
        return 'No pudimos contactar al servidor. Revisa tu conexión.';
      }
    }
    return 'Correo o contraseña incorrectos. Verifica tus datos.';
  }

  void _useDemo(String email) {
    setState(() {
      _email.text = email;
      _password.text = 'admin123';
      _emailErr = null;
      _passErr = null;
      _generalErr = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: _form(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.dark,
        padding: EdgeInsets.fromLTRB(
          28,
          MediaQuery.paddingOf(context).top + 32,
          28,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BIENVENIDA DE NUEVO',
              style: AppTextStyles.bodySize(
                12,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Inicia sesión',
              style: AppTextStyles.displaySize(28, color: Colors.white),
            ),
          ],
        ),
      );

  Widget _form() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_generalErr != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                border: Border.all(color: const Color(0xFFFCA5A5)),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _generalErr!,
                      style: AppTextStyles.bodySize(12, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          DTextField(
            label: 'Correo electrónico',
            controller: _email,
            hint: 'ana@ejemplo.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            errorText: _emailErr,
          ),
          const SizedBox(height: 16),
          DTextField(
            label: 'Contraseña',
            controller: _password,
            hint: '••••••••',
            obscure: !_showPass,
            prefixIcon: Icons.lock_outline,
            errorText: _passErr,
            suffix: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.mutedLight,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '¿Olvidaste tu contraseña?',
              style: AppTextStyles.bodySize(12,
                  color: AppColors.accent, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 24),
          DButton(
            label: _loading ? 'Verificando...' : 'Ingresar',
            tone: DButtonTone.dark,
            expanded: true,
            size: DButtonSize.lg,
            loading: _loading,
            onPressed: _login,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('o continúa con',
                    style: AppTextStyles.bodySize(12, color: AppColors.mutedLight)),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 24),
          _social('Continuar con Google', Icons.g_mobiledata),
          const SizedBox(height: 10),
          _social('Continuar con Apple', Icons.apple),
          const SizedBox(height: 28),
          _demoCard(),
          const SizedBox(height: 28),
          Center(
            child: GestureDetector(
              onTap: widget.onGoRegister,
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySize(13, color: AppColors.muted),
                  children: const [
                    TextSpan(text: '¿No tienes cuenta? '),
                    TextSpan(
                      text: 'Regístrate',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _demoCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CUENTAS DEMO (CONTRASEÑA admin123)',
              style: AppTextStyles.bodySize(10,
                  color: AppColors.muted,
                  weight: FontWeight.w700,
                  letterSpacing: 0.6),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mail in const [
                  'cliente@fashionstore.com',
                  'admin@fashionstore.com',
                  'cajero@fashionstore.com',
                ])
                  GestureDetector(
                    onTap: () => _useDemo(mail),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        mail.split('@').first,
                        style: AppTextStyles.bodySize(11,
                            color: AppColors.accentDark, weight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _social(String label, IconData icon) => GestureDetector(
        onTap: () => _useDemo('cliente@fashionstore.com'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.dark),
              const SizedBox(width: 10),
              Text(label, style: AppTextStyles.bodySize(14, weight: FontWeight.w500)),
            ],
          ),
        ),
      );
}
