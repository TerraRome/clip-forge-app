import 'package:flutter/material.dart';
import 'extensions/color_extension.dart';
import 'tokens/color_tokens.dart';
import 'tokens/spacing_tokens.dart';
import 'tokens/typography_tokens.dart';

/// Application theme definitions.
///
/// Every visual value originates from design_system.md.
/// M3 is used as architectural base; all tokens are custom.
class AppTheme {
  AppTheme._();

  static const double _buttonHeight = 56; // touchButton §9.1

  static ThemeData get light => _build(
    brightness: Brightness.light,
    colors: const ColorTokens(),
    colorExtension: AppColorExtension.light(),
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    colors: const DarkColorTokens(),
    colorExtension: AppColorExtension.dark(),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorTokens colors,
    required AppColorExtension colorExtension,
  }) {
    return ThemeData(
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[colorExtension],
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      disabledColor: colors.textTertiary,
      fontFamily: 'Inter',

      // AppBar — §7.2 flat with bottom border
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        titleTextStyle: TypographyTokens.title,
        surfaceTintColor: Colors.transparent,
      ),

      // Card — §9.2
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusMd),
          side: BorderSide(color: colors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated button (primary) — §9.1
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.primary,
          disabledForegroundColor: colors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          minimumSize: const Size(double.infinity, _buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xl,
            vertical: SpacingTokens.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          ),
          textStyle: TypographyTokens.bodyMedium,
        ),
      ),

      // Outlined button (secondary outlined) — §9.1
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textTertiary,
          side: BorderSide(color: colors.border),
          minimumSize: const Size(double.infinity, _buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xl,
            vertical: SpacingTokens.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          ),
          textStyle: TypographyTokens.bodyMedium,
        ),
      ),

      // Text button (secondary text variant) — §9.1
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.textPrimary,
          disabledForegroundColor: colors.textTertiary,
          minimumSize: const Size(double.infinity, _buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.xl,
            vertical: SpacingTokens.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          ),
          textStyle: TypographyTokens.bodyMedium,
        ),
      ),

      // Input field — §9.3
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md,
          vertical: SpacingTokens.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusSm),
          borderSide: BorderSide(color: colors.border),
        ),
        labelStyle: TypographyTokens.body.copyWith(color: colors.textSecondary),
        hintStyle: TypographyTokens.body.copyWith(color: colors.textTertiary),
        errorStyle: TypographyTokens.caption.copyWith(
          color: colors.error,
          height: 1.0,
        ),
      ),

      // Chip — §9.8
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceVariant,
        labelStyle: TypographyTokens.captionBold,
        secondaryLabelStyle: TypographyTokens.caption,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusFull),
        ),
        side: BorderSide(color: colors.border),
        disabledColor: colors.surfaceVariant,
        selectedColor: colors.primaryContainer,
        selectedShadowColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        brightness: brightness,
      ),

      // Dialog — §9.4
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusLg),
        ),
        titleTextStyle: TypographyTokens.title.copyWith(
          color: colors.textPrimary,
        ),
        contentTextStyle: TypographyTokens.body.copyWith(
          color: colors.textSecondary,
        ),
      ),

      // Bottom sheet — §9.5
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(SpacingTokens.radiusXl),
          ),
        ),
        dragHandleColor: colors.border,
        dragHandleSize: const Size(32, 4),
      ),

      // Snackbar — §9.6
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surface,
        contentTextStyle: TypographyTokens.body.copyWith(
          color: colors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SpacingTokens.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      // Divider — §3.6
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),

      // Indicator for indeterminate progress — §9.13
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearMinHeight: 4,
      ),
    );
  }
}
