import 'package:flutter/material.dart';
import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';
import 'color_extension.dart';

/// Accessor extension on `BuildContext` for convenient design token access.
///
/// `.colors` reads from [AppColorExtension] registered in [ThemeData.extensions].
/// Automatically resolves light/dark palette based on current [ThemeData].
/// `.typography` and `.spacing` remain static const (no theme variation).
///
/// Usage: `context.colors.primary` — resolves to correct palette.
///
/// ponytail: if more token categories gain theme variation in future,
/// promote all to ThemeExtension pattern.
extension ThemeX on BuildContext {
  ColorTokens get colors =>
      Theme.of(this).extension<AppColorExtension>() ??
      AppColorExtension.light();
  TypographyTokens get typography => const TypographyTokens();
  SpacingTokens get spacing => const SpacingTokens();
}
