import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Campo de texto del prototipo: etiqueta arriba + input blanco redondeado.
class DTextField extends StatelessWidget {
  const DTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.maxLines = 1,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySize(
            12,
            color: AppColors.muted,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: obscure ? 1 : maxLines,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          style: AppTextStyles.bodySize(14),
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            isDense: true,
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.borderLight,
            prefixIcon: prefixIcon == null
                ? null
                : Icon(prefixIcon, size: 18, color: AppColors.mutedLight),
            suffixIcon: suffix,
            hintStyle: AppTextStyles.bodySize(14, color: AppColors.mutedLight),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 14,
            ),
            enabledBorder: _border(AppColors.border),
            focusedBorder: _border(AppColors.accent, width: 1.6),
            errorBorder: _border(AppColors.danger),
            focusedErrorBorder: _border(AppColors.danger, width: 1.6),
            disabledBorder: _border(AppColors.border),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.2}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
}
