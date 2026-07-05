import 'package:flutter/material.dart';

// ponytail: convert to ThemeExtension<ColorTokens> when first widget uses context.colorTokens
/// Light color tokens per design_system.md §3.
///
/// Subclassing supported for extension accessors.
class ColorTokens {
  const ColorTokens();

  Color get primary => const Color(0xFF6C5CE7);
  Color get primaryContainer => const Color(0xFFEDE9FE);
  Color get onPrimary => const Color(0xFFFFFFFF);

  Color get secondary => const Color(0xFF00CEC9);

  Color get background => const Color(0xFFF7F7F8);
  Color get surface => const Color(0xFFFFFFFF);
  Color get surfaceVariant => const Color(0xFFF0F0F2);

  Color get textPrimary => const Color(0xFF1A1A2E);
  Color get textSecondary => const Color(0xFF6B7280);
  Color get textTertiary => const Color(0xFF9CA3AF);

  Color get border => const Color(0xFFE5E7EB);
  Color get divider => const Color(0xFFF0F0F2);

  Color get error => const Color(0xFFEF4444);
  Color get success => const Color(0xFF10B981);
  Color get warning => const Color(0xFFF59E0B);

  Color get overlay => const Color(0x66000000);
  Color get skeleton => const Color(0xFFE5E7EB);
  Color get skeletonHighlight => const Color(0xFFF3F4F6);
  Color get shadow => const Color(0x14000000);
}

/// Dark color tokens per design_system.md §3.
class DarkColorTokens extends ColorTokens {
  const DarkColorTokens();

  @override
  Color get primary => const Color(0xFF6C5CE7);
  @override
  Color get primaryContainer => const Color(0xFF2D2640);
  @override
  Color get onPrimary => const Color(0xFFFFFFFF);

  @override
  Color get secondary => const Color(0xFF00CEC9);

  @override
  Color get background => const Color(0xFF0D0D0F);
  @override
  Color get surface => const Color(0xFF1C1C1E);
  @override
  Color get surfaceVariant => const Color(0xFF2C2C2E);

  @override
  Color get textPrimary => const Color(0xFFF5F5F7);
  @override
  Color get textSecondary => const Color(0xFF9CA3AF);
  @override
  Color get textTertiary => const Color(0xFF6B7280);

  @override
  Color get border => const Color(0xFF38383A);
  @override
  Color get divider => const Color(0xFF2C2C2E);

  @override
  Color get error => const Color(0xFFF87171);
  @override
  Color get success => const Color(0xFF34D399);
  @override
  Color get warning => const Color(0xFFFBBF24);

  @override
  Color get overlay => const Color(0x99000000);
  @override
  Color get skeleton => const Color(0xFF38383A);
  @override
  Color get skeletonHighlight => const Color(0xFF48484A);
  @override
  Color get shadow => const Color(0x4D000000);
}
