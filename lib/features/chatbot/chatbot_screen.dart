import 'package:flutter/material.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/nav.dart';

class _Msg {
  final String role;
  final String text;
  final DateTime ts;
  _Msg(this.role, this.text, this.ts);
}

const _quick = [
  '¿Cómo devuelvo un producto?',
  '¿Tienen envío gratis?',
  'Código de descuento',
  '¿Cómo reservo un probador?',
];

String _botReply(String text) {
  final t = text.toLowerCase();
  if (t.contains('talla')) {
    return 'Para encontrar tu talla ideal, te recomendamos usar nuestra Guía de Tallas disponible en cada producto. También puedes reservar un turno en el Probador Virtual.';
  }
  if (t.contains('envío') || t.contains('envio')) {
    return 'El envío estándar tarda 3–5 días hábiles con un costo de \$4.99. El retiro en tienda está disponible en 24 horas sin costo adicional.';
  }
  if (t.contains('pago')) {
    return 'Aceptamos Visa, Mastercard, American Express, Apple Pay y Google Pay. Todos los pagos se procesan de forma segura mediante Stripe.';
  }
  if (t.contains('devol')) {
    return 'Puedes devolver o cambiar un producto dentro de los 30 días desde la compra. El artículo debe estar sin uso y con sus etiquetas originales.';
  }
  if (t.contains('reserva')) {
    return 'Para reservar un probador, ve a la pestaña "Reservas" en la navegación inferior, elige el producto, la sucursal y el horario disponible.';
  }
  if (t.contains('descuento') || t.contains('código') || t.contains('codigo')) {
    return '¡Claro! Usa el código FASHION10 en tu carrito para obtener un 10% de descuento en tu próxima compra.';
  }
  if (t.contains('horario')) {
    return 'Nuestras sucursales abren de lunes a sábado de 10:00 a 21:00 hs. La Sucursal Sur cierra a las 20:00 hs.';
  }
  if (t.contains('hola') || t.contains('buenas')) {
    return '¡Hola! Soy el asistente virtual de FashionStore. ¿En qué puedo ayudarte hoy?';
  }
  if (t.contains('gracias')) {
    return '¡De nada! ¿Hay algo más en lo que pueda ayudarte?';
  }
  return 'Entiendo tu consulta. Para más información, puedes revisar nuestra sección de Ayuda y Soporte o contactarnos por correo a soporte@fashionstore.com';
}

/// Asistente virtual con respuestas rápidas y burbujas de chat.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [
    _Msg('assistant',
        '¡Hola! Soy el asistente de FashionStore 👗 ¿En qué puedo ayudarte hoy?', DateTime.now()),
  ];
  bool _typing = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(_Msg('user', t, DateTime.now()));
      _input.clear();
      _typing = true;
    });
    _scrollDown();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg('assistant', _botReply(t), DateTime.now()));
        _typing = false;
      });
      _scrollDown();
    });
  }

  String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(
          title: 'Asistente FashionStore',
          onBack: s.closeOverlay,
          right: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('En línea',
                  style: AppTextStyles.bodySize(11, color: AppColors.muted)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            children: [
              ..._messages.map(_bubble),
              if (_typing) _typingBubble(),
              if (_messages.length <= 2 && !_typing) _quickReplies(),
            ],
          ),
        ),
        _inputBar(),
      ],
    );
  }

  Widget _bubble(_Msg m) {
    final isUser = m.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.dark,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.chat_bubble_outline,
                  size: 15, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.dark : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    m.text,
                    style: AppTextStyles.bodySize(
                      13,
                      color: isUser ? Colors.white : AppColors.dark,
                      height: 1.55,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(_fmt(m.ts),
                      style: AppTextStyles.bodySize(10,
                          color: AppColors.mutedLight)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble() => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.dark,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.chat_bubble_outline,
                size: 15, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (_) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  decoration: const BoxDecoration(
                    color: AppColors.mutedLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  Widget _quickReplies() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preguntas frecuentes:',
                style: AppTextStyles.bodySize(11, color: AppColors.mutedLight)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quick
                  .map((q) => GestureDetector(
                        onTap: () => _send(q),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(q,
                              style: AppTextStyles.bodySize(11,
                                  weight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      );

  Widget _inputBar() => Container(
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _input,
                  onChanged: (_) => setState(() {}),
                  maxLines: 3,
                  minLines: 1,
                  style: AppTextStyles.bodySize(13),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    hintText: 'Escribe tu mensaje…',
                    hintStyle:
                        AppTextStyles.bodySize(13, color: AppColors.mutedLight),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _input.text.trim().isEmpty ? null : () => _send(_input.text),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _input.text.trim().isEmpty
                      ? AppColors.borderLight
                      : AppColors.dark,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.send,
                  size: 16,
                  color: _input.text.trim().isEmpty
                      ? AppColors.mutedLight
                      : Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
}
