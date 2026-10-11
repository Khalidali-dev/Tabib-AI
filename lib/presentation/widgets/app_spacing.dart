import 'package:flutter/material.dart';

/// Centralized, high-performance spacing constants and widgets for Tabib.
/// Eliminates boilerplate SizedBox instantiation across the entire codebase.
class AppGap {
  const AppGap._();

  // Vertical Gaps
  static const Widget h2 = SizedBox(height: 2);
  static const Widget h4 = SizedBox(height: 4);
  static const Widget h6 = SizedBox(height: 6);
  static const Widget h8 = SizedBox(height: 8);
  static const Widget h10 = SizedBox(height: 10);
  static const Widget h12 = SizedBox(height: 12);
  static const Widget h14 = SizedBox(height: 14);
  static const Widget h16 = SizedBox(height: 16);
  static const Widget h20 = SizedBox(height: 20);
  static const Widget h24 = SizedBox(height: 24);
  static const Widget h28 = SizedBox(height: 28);
  static const Widget h32 = SizedBox(height: 32);
  static const Widget h40 = SizedBox(height: 40);
  static const Widget h48 = SizedBox(height: 48);

  // Horizontal Gaps
  static const Widget w2 = SizedBox(width: 2);
  static const Widget w4 = SizedBox(width: 4);
  static const Widget w6 = SizedBox(width: 6);
  static const Widget w8 = SizedBox(width: 8);
  static const Widget w10 = SizedBox(width: 10);
  static const Widget w12 = SizedBox(width: 12);
  static const Widget w14 = SizedBox(width: 14);
  static const Widget w16 = SizedBox(width: 16);
  static const Widget w20 = SizedBox(width: 20);
  static const Widget w24 = SizedBox(width: 24);
  static const Widget w32 = SizedBox(width: 32);

  // Dynamic helpers
  static Widget h(double height) => SizedBox(height: height);
  static Widget w(double width) => SizedBox(width: width);
}

/// Convenience extension on numbers for readable spacing: e.g. 12.hGap, 8.wGap
extension AppGapExtension on num {
  Widget get hGap => SizedBox(height: toDouble());
  Widget get wGap => SizedBox(width: toDouble());
}

/// Reusable responsive wrapper ensuring consistent presentation across phone and tablet
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 860,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Reusable glassmorphic card container with automatic dark/light mode borders and shadows
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? customBg;
  final Color? customBorderColor;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius,
    this.customBg,
    this.customBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = borderRadius ?? BorderRadius.circular(18);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: customBg ??
            (isDark ? const Color(0xFF142035) : Colors.white),
        borderRadius: r,
        border: Border.all(
          color: customBorderColor ??
              (isDark ? const Color(0xFF223555) : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Reusable spinner to avoid repetitive SizedBox(width, height, child: CircularProgressIndicator)
class AppSpinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const AppSpinner({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

