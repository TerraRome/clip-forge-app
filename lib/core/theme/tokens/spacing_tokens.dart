/// Design spacing and sizing tokens.
/// Follows a 4dp base grid scale per design_system.md §5.
class SpacingTokens {
  const SpacingTokens();

  // 4dp base grid — §5.2
  static const double xxs = 4; // 1×
  static const double xs = 8; // 2×
  static const double sm = 12; // 3×
  static const double md = 16; // 4×
  static const double lg = 20; // 5×
  static const double xl = 24; // 6×
  static const double xxl = 32; // 8×
  static const double xxxl = 40; // 10×
  static const double huge = 48; // 12×
  static const double massive = 64; // 16×

  // Radius tokens — §6.1
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999; // pill shape
}
