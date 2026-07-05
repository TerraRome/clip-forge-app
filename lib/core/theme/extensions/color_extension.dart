import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';

/// ThemeExtension that adapts [ColorTokens] to light/dark mode.
///
/// Registered in [ThemeData.extensions]. Accessed via [ThemeX.colors].
/// This is the *only* token category that needs ThemeExtension because
/// colors differ between light and dark (design_system.md §13.4).
/// All other token categories (spacing, typography, radius, motion,
/// elevation) are static const — they do not vary by theme.
class AppColorExtension extends ThemeExtension<AppColorExtension>
    implements ColorTokens {
  const AppColorExtension({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.divider,
    required this.error,
    required this.success,
    required this.warning,
    required this.overlay,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.shadow,
  });

  AppColorExtension._from(ColorTokens t)
    : this(
        primary: t.primary,
        primaryContainer: t.primaryContainer,
        onPrimary: t.onPrimary,
        secondary: t.secondary,
        background: t.background,
        surface: t.surface,
        surfaceVariant: t.surfaceVariant,
        textPrimary: t.textPrimary,
        textSecondary: t.textSecondary,
        textTertiary: t.textTertiary,
        border: t.border,
        divider: t.divider,
        error: t.error,
        success: t.success,
        warning: t.warning,
        overlay: t.overlay,
        skeleton: t.skeleton,
        skeletonHighlight: t.skeletonHighlight,
        shadow: t.shadow,
      );

  /// Light palette — values from [ColorTokens] (default light).
  factory AppColorExtension.light() =>
      AppColorExtension._from(const ColorTokens());

  /// Dark palette — values from [DarkColorTokens].
  factory AppColorExtension.dark() =>
      AppColorExtension._from(const DarkColorTokens());

  @override
  final Color primary;
  @override
  final Color primaryContainer;
  @override
  final Color onPrimary;
  @override
  final Color secondary;
  @override
  final Color background;
  @override
  final Color surface;
  @override
  final Color surfaceVariant;
  @override
  final Color textPrimary;
  @override
  final Color textSecondary;
  @override
  final Color textTertiary;
  @override
  final Color border;
  @override
  final Color divider;
  @override
  final Color error;
  @override
  final Color success;
  @override
  final Color warning;
  @override
  final Color overlay;
  @override
  final Color skeleton;
  @override
  final Color skeletonHighlight;
  @override
  final Color shadow;

  @override
  AppColorExtension copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? onPrimary,
    Color? secondary,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? divider,
    Color? error,
    Color? success,
    Color? warning,
    Color? overlay,
    Color? skeleton,
    Color? skeletonHighlight,
    Color? shadow,
  }) {
    return AppColorExtension(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      overlay: overlay ?? this.overlay,
      skeleton: skeleton ?? this.skeleton,
      skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension other, double t) {
    if (t == 0.0) return this;
    if (t == 1.0) return other;
    return AppColorExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      skeleton: Color.lerp(skeleton, other.skeleton, t)!,
      skeletonHighlight: Color.lerp(
        skeletonHighlight,
        other.skeletonHighlight,
        t,
      )!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}
