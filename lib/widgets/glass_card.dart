import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// A glass-morphism card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Border? border;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 15,
    this.backgroundColor,
    this.border,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.glassWhite,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ??
                Border.all(color: AppColors.glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}
