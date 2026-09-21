import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/inputs.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

/// Registro del prototipo, conectado a `POST /auth/register`.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.auth,
    required this.onSuccess,
    required this.onGoLogin,
  });

  final AuthRepository auth;
  final VoidCallback onSuccess;
  final VoidCallback onGoLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  bool _accept = false;
  String? _nameErr;
  String? _emailErr;
  String? _passErr;
  String? _confirmErr;
  String? _generalErr;

  static const _strengthLabel = ['', 'Débil', 'Regular', 'Buena', 'Fuerte'];
  static const _strengthColor = [
    Colors.transparent,
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF059669),
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int get _strength {
    final p = _password.text;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  bool _validate() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    String? n;
    String? e;
    String? p;
    String? c;
    String? g;
    if (name.isEmpty) {
      n = 'El nombre es obligatorio';
    } else if (name.length < 2) {
      n = 'Mínimo 2 caracteres';
    }
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
    if (_password.text != _confirm.text) {
      c = 'Las contraseñas no coinciden';
    }
    if (!_accept) g = 'Debes aceptar los términos y condiciones';
    setState(() {
      _nameErr = n;
      _emailErr = e;
      _passErr = p;
      _confirmErr = c;
      _generalErr = g;
    });
    return n == null && e == null && p == null && c == null && g == null;
  }

  Future<void> _register() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    final email = _email.text.trim();
    try {
      await widget.auth.register(RegisterRequest(
        email: email,
        fullName: _name.text.trim(),
        password: _password.text,
      ));
      try {
        await widget.auth.login(email, _password.text);
      } catch (_) {
        // La cuenta ya quedó creada; si el login falla seguimos al shell.
      }
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
    return 'No pudimos crear tu cuenta. Inténtalo de nuevo.';
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
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
              'ÚNETE A FASHIONSTORE',
              style: AppTextStyles.bodySize(
                12,
                color: Colors.white.withValues(alpha: 0.55),
                letterSpacing: 0.7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crea tu cuenta',
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
            label: 'Nombre completo',
            controller: _name,
            hint: 'Ana López',
            prefixIcon: Icons.person_outline,
            errorText: _nameErr,
          ),
          const SizedBox(height: 14),
          DTextField(
            label: 'Correo electrónico',
            controller: _email,
            hint: 'ana@ejemplo.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            errorText: _emailErr,
          ),
          const SizedBox(height: 14),
          DTextField(
            label: 'Contraseña',
            controller: _password,
            hint: 'Mínimo 6 caracteres',
            obscure: !_showPass,
            prefixIcon: Icons.lock_outline,
            errorText: _passErr,
            onChanged: (_) => setState(() {}),
            suffix: IconButton(
              icon: Icon(
                _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.mutedLight,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
          if (_password.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _strengthBar(),
          ],
          const SizedBox(height: 14),
          DTextField(
            label: 'Confirmar contraseña',
            controller: _confirm,
            hint: 'Repite tu contraseña',
            obscure: !_showPass,
            prefixIcon: Icons.lock_outline,
            errorText: _confirmErr,
          ),
          const SizedBox(height: 20),
          _terms(),
          const SizedBox(height: 20),
          DButton(
            label: _loading ? 'Creando cuenta...' : 'Crear cuenta',
            tone: DButtonTone.dark,
            expanded: true,
            size: DButtonSize.lg,
            loading: _loading,
            onPressed: _register,
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: widget.onGoLogin,
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySize(13, color: AppColors.muted),
                  children: const [
                    TextSpan(text: '¿Ya tienes cuenta? '),
                    TextSpan(
                      text: 'Inicia sesión',
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

  Widget _strengthBar() {
    final s = _strength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: i < s ? _strengthColor[s] : AppColors.borderLight,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          _strengthLabel[s],
          style: AppTextStyles.bodySize(11,
              color: _strengthColor[s], weight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _terms() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _accept = !_accept),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _accept ? AppColors.dark : AppColors.border,
                  width: 2,
                ),
                color: _accept ? AppColors.dark : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: _accept
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySize(12,
                    color: AppColors.muted, height: 1.5),
                children: const [
                  TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos y condiciones',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de privacidad',
                    style: TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
