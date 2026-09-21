import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Imagen remota con placeholder y fallback (espejo de `<img>` del prototipo).
class NetImage extends StatelessWidget {
  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.radius,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final child = url.isEmpty
        ? _placeholder()
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => _placeholder(),
            errorWidget: (_, __, ___) => _placeholder(),
          );
    if (radius == null) return child;
    return ClipRRect(borderRadius: radius!, child: child);
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.borderLight,
        alignment: Alignment.center,
        child: const Icon(Icons.checkroom, color: AppColors.mutedLight, size: 28),
      );
}
