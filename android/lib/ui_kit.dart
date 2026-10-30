import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'app_preferences.dart';

const binerBlue = Color(0xFF54C8FF);
const binerViolet = Color(0xFF9B8CFF);

/// Shared Material 3 theme with a Persian-friendly typeface and adaptive surfaces.
ThemeData buildBinerTheme(Brightness brightness, {Color seedColor = binerBlue}) {
  final dark = brightness == Brightness.dark;
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final textColor = dark ? const Color(0xFFF4F7FF) : const Color(0xFF142033);
  return base.copyWith(
    brightness: brightness,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surface: dark ? const Color(0xFF08080B) : const Color(0xFFF8FAFF),
      secondary: binerViolet,
    ),
    textTheme: GoogleFonts.notoSansArabicTextTheme(base.textTheme).apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xF20D0D12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: binerBlue.withValues(alpha: .38))),
      textStyle: TextStyle(color: dark ? const Color(0xFFF5F5F7) : const Color(0xFF142033)),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xF21A1A20), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: binerBlue.withValues(alpha: .38))), insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), contentTextStyle: TextStyle(color: dark ? const Color(0xFFF5F5F7) : const Color(0xFF142033), fontWeight: FontWeight.w600)),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    }),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xAA111D30) : const Color(0xFFF0F4FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: dark ? const Color(0x5537BFFF) : const Color(0x553D7DB5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: dark ? const Color(0x5537BFFF) : const Color(0x443D7DB5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: binerBlue, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: binerBlue.withValues(alpha: .18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        color: states.contains(WidgetState.selected) ? binerBlue : (dark ? const Color(0xFF9BAEC6) : const Color(0xFF5C6C82)),
      )),
    ),
  );
}

/// Ambient, low-cost radial lighting behind transparent app surfaces.
class BinerBackdrop extends StatelessWidget {
  const BinerBackdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF000000), Color(0xFF050509), Color(0xFF000000)]
                  : const [Color(0xFFF4F8FF), Color(0xFFEAF3FF), Color(0xFFF9FAFF)],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: _AmbientGlowPainter(dark: dark)),
        ),
        child,
      ],
    );
  }
}

class _AmbientGlowPainter extends CustomPainter {
  const _AmbientGlowPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..shader = RadialGradient(
        colors: [
          binerBlue.withValues(alpha: dark ? .15 : .13),
          binerBlue.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .92, size.height * .08), radius: size.width * .72));
    canvas.drawCircle(Offset(size.width * .92, size.height * .08), size.width * .72, blue);

    final violet = Paint()
      ..shader = RadialGradient(
        colors: [
          binerViolet.withValues(alpha: dark ? .13 : .10),
          binerViolet.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .04, size.height * .72), radius: size.width * .62));
    canvas.drawCircle(Offset(size.width * .04, size.height * .72), size.width * .62, violet);
  }

  @override
  bool shouldRepaint(covariant _AmbientGlowPainter oldDelegate) => oldDelegate.dark != dark;
}

/// Liquid-glass surface: clipped blur, translucent gradient, hairline border and soft depth.
class BinerLiquidGlass extends StatelessWidget {
  const BinerLiquidGlass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: BinerPreferences.instance.fastMode ? 0 : 12, sigmaY: BinerPreferences.instance.fastMode ? 0 : 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? [const Color(0xE60D0D12), const Color(0xD908080B)]
                    : [const Color(0xDDFEFFFF), const Color(0xBFEAF2FC)],
              ),
              border: Border.all(
                color: dark ? const Color(0x5539C5FF) : const Color(0x553D7DB5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (dark ? binerBlue : const Color(0xFF4777AA)).withValues(alpha: .10),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Reusable skeleton blocks for network-bound screens.
class BinerSkeleton extends StatelessWidget {
  const BinerSkeleton({super.key, this.lines = 3});
  final int lines;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF15151B) : const Color(0xFFDDE6F1),
      highlightColor: dark ? const Color(0xFF24242D) : const Color(0xFFF7FAFF),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 22, backgroundColor: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, width: 142, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 12),
                  for (var i = 0; i < lines; i++) ...[
                    FractionallySizedBox(
                      widthFactor: i == lines - 1 ? .58 : .94,
                      child: Container(height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7))),
                    ),
                    const SizedBox(height: 9),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small adaptive back affordance for Cupertino-style subpages.
class BinerAdaptiveBackButton extends StatelessWidget {
  const BinerAdaptiveBackButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'بازگشت',
    onPressed: onPressed ?? () => Navigator.maybePop(context),
    icon: Icon(
      Theme.of(context).platform == TargetPlatform.iOS
          ? CupertinoIcons.back
          : Icons.arrow_back_rounded,
    ),
  ).animate().fadeIn(duration: 180.ms).scale(begin: const Offset(.92, .92));
}

/// Decorative custom clipper available for hero/banner surfaces.
class BinerHeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height * .78)
    ..quadraticBezierTo(size.width * .55, size.height * 1.08, 0, size.height * .82)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
