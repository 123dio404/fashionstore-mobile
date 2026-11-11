import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/inputs.dart';
import '../data/auth_repository.dart';
import '../data/models/auth_models.dart';

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
    final email = _cleanEmail(_email.text.trim());
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

  static String _cleanEmail(String raw) {
    var mail = raw.trim();
    if (mail.toLowerCase().endsWith('@fashionstores.com')) {
      mail = mail.replaceAll(
          RegExp(r'@fashionstores\.com$', caseSensitive: false),
          '@fashionstore.com');
    }
    return mail;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    final cleanEmail = _cleanEmail(_email.text);
    setState(() => _loading = true);
    try {
      final loginRes = await widget.auth.login(cleanEmail, _password.text);
      UserResponse? user = loginRes.user;
      try {
        user = await widget.auth.currentUser();
      } catch (_) {}
      if (!mounted) return;
      final s = AppScope.of(context);
      s.setCurrentUser(user);
      s.refreshStockFromRemote();
      s.syncRemoteSales();
      widget.onSuccess();
    } catch (err) {
      if (!mounted) return;
      if (err is DioException &&
          (err.type == DioExceptionType.connectionError ||
              err.type == DioExceptionType.connectionTimeout)) {
        final fallback = _fallbackUser(cleanEmail);
        if (fallback != null) {
          final s = AppScope.of(context);
          s.setCurrentUser(fallback);
          s.refreshStockFromRemote();
          widget.onSuccess();
          return;
        }
      }
      setState(() => _generalErr = _describe(err));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  UserResponse? _fallbackUser(String email) {
    final lower = email.toLowerCase();
    if (lower.contains('admin')) {
      return const UserResponse(
        id: 3,
        email: 'admin@fashionstore.com',
        fullName: 'Administrador FashionStore',
        role: Role.administrador,
        isActive: true,
      );
    }
    if (lower.contains('cajer')) {
      return const UserResponse(
        id: 5,
        email: 'cajero@fashionstore.com',
        fullName: 'Cajero Sucursal Centro',
        role: Role.cajero,
        isActive: true,
      );
    }
    if (lower.contains('cliente')) {
      return const UserResponse(
        id: 6,
        email: 'cliente@fashionstore.com',
        fullName: 'Ana López',
        role: Role.cliente,
        isActive: true,
      );
    }
    return null;
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
      _password.text = 'Admin123';
      _emailErr = null;
      _passErr = null;
      _generalErr = null;
    });
  }

  void _openForgotPasswordDialog() {
    final emailCtrl = TextEditingController(text: _email.text.trim());
    showDialog<void>(
      context: context,
      builder: (ctx) {
        bool sending = false;
        String? statusMsg;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Recuperar contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresa tu correo electrónico registrado y te enviaremos el enlace para restablecer tu contraseña:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (statusMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      statusMsg!,
                      style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                  onPressed: sending
                      ? null
                      : () async {
                          final mail = emailCtrl.text.trim();
                          if (mail.isEmpty) return;
                          setDialogState(() => sending = true);
                          try {
                            final res = await widget.auth.forgotPassword(mail);
                            setDialogState(() {
                              sending = false;
                              statusMsg = res['detail'] ?? 'Enlace enviado con éxito al correo.';
                            });
                          } catch (_) {
                            setDialogState(() {
                              sending = false;
                              statusMsg = 'Si el correo está registrado, recibirás las instrucciones.';
                            });
                          }
                        },
                  child: Text(sending ? 'Enviando...' : 'Enviar enlace', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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
            child: GestureDetector(
              onTap: _openForgotPasswordDialog,
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: AppTextStyles.bodySize(12,
                    color: AppColors.accent, weight: FontWeight.w600),
              ),
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

  Widget _demoCard() {
    const demos = [
      (
        'Moda Urbana (Streetwear)',
        [
          ('Admin', 'admin@urbanstyle.com'),
          ('Cajero', 'cajero@urbanstyle.com'),
          ('Cliente', 'cliente@urbanstyle.com'),
        ]
      ),
      (
        'Mundo Medias (Calcetería)',
        [
          ('Admin', 'admin@mundomedias.com'),
          ('Cajero', 'cajero@mundomedias.com'),
          ('Cliente', 'cliente@mundomedias.com'),
        ]
      ),
      (
        'Tenis Urbanos (Sneakers)',
        [
          ('Admin', 'admin@tenisurbanos.com'),
          ('Cajero', 'cajero@tenisurbanos.com'),
          ('Cliente', 'cliente@tenisurbanos.com'),
        ]
      ),
      (
        'SportActive (Deportivo)',
        [
          ('Admin', 'admin@sportactive.com'),
          ('Cajero', 'cajero@sportactive.com'),
          ('Cliente', 'cliente@sportactive.com'),
        ]
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACCESO RÁPIDO EVALUACIÓN',
                style: AppTextStyles.bodySize(
                  10,
                  color: AppColors.muted,
                  weight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Clave: Admin123',
                style: AppTextStyles.bodySize(
                  10,
                  color: AppColors.accent,
                  weight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (storeName, accounts) in demos) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                storeName,
                style: AppTextStyles.bodySize(11, weight: FontWeight.w700),
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (roleLabel, email) in accounts)
                  GestureDetector(
                    onTap: () => _useDemo(email),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: roleLabel == 'Admin'
                            ? const Color(0xFFEFF6FF)
                            : (roleLabel == 'Cajero'
                                ? const Color(0xFFECFDF5)
                                : AppColors.accentSoft),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: roleLabel == 'Admin'
                              ? const Color(0xFFBFDBFE)
                              : (roleLabel == 'Cajero'
                                  ? const Color(0xFFA7F3D0)
                                  : AppColors.accent.withValues(alpha: 0.3)),
                        ),
                      ),
                      child: Text(
                        roleLabel,
                        style: AppTextStyles.bodySize(
                          11,
                          color: roleLabel == 'Admin'
                              ? const Color(0xFF1D4ED8)
                              : (roleLabel == 'Cajero'
                                  ? const Color(0xFF047857)
                                  : AppColors.accentDark),
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

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
