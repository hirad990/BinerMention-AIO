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
  final selectedTextTheme = switch (BinerPreferences.instance.fontFamily) {
    'system' => base.textTheme,
    'vazir' => GoogleFonts.getTextTheme('Vazirmatn', base.textTheme),
    _ => GoogleFonts.notoSansArabicTextTheme(base.textTheme),
  };
  return base.copyWith(
    brightness: brightness,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surface: dark ? const Color(0xFF08080B) : const Color(0xFFF8FAFF),
      secondary: binerViolet,
    ),
    textTheme: selectedTextTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xF20D0D12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: seedColor.withValues(alpha: .38))),
      textStyle: TextStyle(color: dark ? const Color(0xFFF5F5F7) : const Color(0xFF142033)),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xF21A1A20), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: seedColor.withValues(alpha: .38))), insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), contentTextStyle: TextStyle(color: dark ? const Color(0xFFF5F5F7) : const Color(0xFF142033), fontWeight: FontWeight.w600)),
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 62,
      titleTextStyle: TextStyle(color: textColor, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -.2),
      iconTheme: IconThemeData(color: textColor),
    ),
    dividerTheme: DividerThemeData(color: (dark ? Colors.white : const Color(0xFF253B56)).withValues(alpha: .10), thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF101722) : Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: seedColor.withValues(alpha: .14))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xAA111D30) : const Color(0xFFF0F4FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: seedColor.withValues(alpha: .34)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: seedColor.withValues(alpha: .28)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: seedColor, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      indicatorColor: seedColor.withValues(alpha: .18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        color: states.contains(WidgetState.selected) ? seedColor : (dark ? const Color(0xFF9BAEC6) : const Color(0xFF5C6C82)),
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
    final accent = BinerPreferences.instance.accent;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: dark ? const Color(0xFF0B0D12) : const Color(0xFFF5F7FA),
        ),
        // A restrained accent wash keeps the app recognizable without the
        // heavy neon/glass look or expensive full-screen blur effects.
        if (!BinerPreferences.instance.fastMode)
          Positioned(
            top: -150,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [accent.withValues(alpha: dark ? .075 : .055), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: padding,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF141820) : Colors.white,
          borderRadius: borderRadius,
          border: Border.all(
            color: dark ? const Color(0xFF252D39) : const Color(0xFFE4E9F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .12 : .035),
              blurRadius: BinerPreferences.instance.fastMode ? 0 : 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
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
    final skeleton = Padding(
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
    );
    if (BinerPreferences.instance.fastMode) return skeleton;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF15151B) : const Color(0xFFDDE6F1),
      highlightColor: dark ? const Color(0xFF24242D) : const Color(0xFFF7FAFF),
      child: skeleton,
    );
  }
}

/// A small adaptive back affordance for Cupertino-style subpages.
/// A low-cost, reusable surface for dense screens and scrolling lists.
class BinerSurfaceCard extends StatelessWidget {
  const BinerSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
    this.accent,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = accent ?? Theme.of(context).colorScheme.primary;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: dark ? const Color(0xE6101722) : const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tint.withValues(alpha: dark ? .20 : .15)),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF294766)).withValues(alpha: dark ? .12 : .045),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    return Padding(
      padding: margin,
      child: onTap == null
          ? RepaintBoundary(child: content)
          : Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: onTap,
                child: RepaintBoundary(child: content),
              ),
            ),
    );
  }
}

/// Consistent page heading with optional supporting copy and trailing action.
class BinerSectionHeader extends StatelessWidget {
  const BinerSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 4, 2, 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.35)),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.45)),
            ],
          ],
        )),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

/// Friendly empty state shared by feeds, rooms and analytics pages.
class BinerEmptyState extends StatelessWidget {
  const BinerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .20)),
            ),
            child: Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          if (description != null) ...[
            const SizedBox(height: 7),
            Text(description!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.55)),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

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
