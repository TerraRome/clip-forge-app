import 'package:flutter/material.dart';

// ponytail: move to ThemeExtension<ElevationTokens> when context.elevation needed
/// Elevation system per design_system.md §7.
///
/// Each elevation token defines a box shadow with explicit y/blur/spread/opacity.
/// Light and dark variants share the same y/blur/spread; only opacity differs.
class ElevationTokens {
  const ElevationTokens();

  /// Map from elevation level name to shadow list for a given brightness.
  static List<BoxShadow> of(bool isDark) => [
    _none(),
    _sm(isDark),
    _md(isDark),
    _lg(isDark),
    _xl(isDark),
    _dialog(isDark),
  ];

  // -- Per-level factories ------------------------------------------------

  static BoxShadow _none() => const BoxShadow(
    offset: Offset.zero,
    blurRadius: 0,
    spreadRadius: 0,
    color: Colors.transparent,
  );

  static BoxShadow _sm(bool dark) => BoxShadow(
    offset: const Offset(0, 1),
    blurRadius: 4,
    spreadRadius: 0,
    color: Colors.black.withValues(alpha: dark ? 0.06 : 0.06),
  );

  static BoxShadow _md(bool dark) => BoxShadow(
    offset: const Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
    color: Colors.black.withValues(alpha: dark ? 0.08 : 0.08),
  );

  static BoxShadow _lg(bool dark) => BoxShadow(
    offset: const Offset(0, 4),
    blurRadius: 16,
    spreadRadius: -2,
    color: Colors.black.withValues(alpha: dark ? 0.10 : 0.10),
  );

  static BoxShadow _xl(bool dark) => BoxShadow(
    offset: const Offset(0, -4),
    blurRadius: 24,
    spreadRadius: 0,
    color: Colors.black.withValues(alpha: dark ? 0.12 : 0.12),
  );

  static BoxShadow _dialog(bool dark) => BoxShadow(
    offset: const Offset(0, 8),
    blurRadius: 32,
    spreadRadius: -4,
    color: Colors.black.withValues(alpha: dark ? 0.16 : 0.16),
  );

  // -- Convenience: elevation names as index constants -------------------

  static const int e0 = 0; // none
  static const int e1 = 1; // sm
  static const int e2 = 2; // md
  static const int e3 = 3; // lg
  static const int e4 = 4; // xl (upward)
  static const int e5 = 5; // dialog
}
