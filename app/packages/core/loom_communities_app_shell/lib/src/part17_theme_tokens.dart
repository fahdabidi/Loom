part of '../loom_communities_app_shell.dart';

/// Shared neutral card fill used by [LoomCardTheme.deriveFromAccent] when
/// `neutralSurface` is true — the accent color is reserved for highlights
/// (borders, buttons, badges, headings) instead of filling the whole card.
const Color _neutralCardFill = Color(0xff1c2024);

enum LoomButtonShape { pill, rounded, square }

/// Rich, partial button styling. Every field is optional so a JSON author
/// only needs to specify what they want to change; [merge] fills the rest
/// in from a base theme.
class LoomButtonTheme {
  const LoomButtonTheme({
    this.fillColor,
    this.fillOpacity,
    this.borderColor,
    this.borderOpacity,
    this.borderWidth,
    this.foregroundColor,
    this.foregroundOpacity,
    this.shape,
    this.labelWeight,
  });

  final Color? fillColor;
  final double? fillOpacity;
  final Color? borderColor;
  final double? borderOpacity;
  final double? borderWidth;
  final Color? foregroundColor;
  final double? foregroundOpacity;
  final LoomButtonShape? shape;
  final FontWeight? labelWeight;

  Color get resolvedFill =>
      (fillColor ?? Colors.transparent).withValues(alpha: fillOpacity ?? 1.0);
  Color get resolvedBorder =>
      (borderColor ?? Colors.transparent).withValues(
        alpha: borderOpacity ?? 1.0,
      );
  Color get resolvedForeground =>
      (foregroundColor ?? Colors.white).withValues(
        alpha: foregroundOpacity ?? 1.0,
      );
  OutlinedBorder get resolvedShape {
    switch (shape ?? LoomButtonShape.pill) {
      case LoomButtonShape.pill:
        return const StadiumBorder();
      case LoomButtonShape.rounded:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        );
      case LoomButtonShape.square:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        );
    }
  }

  static LoomButtonTheme? merge(LoomButtonTheme? base, LoomButtonTheme? override) {
    if (override == null) return base;
    if (base == null) return override;
    return LoomButtonTheme(
      fillColor: override.fillColor ?? base.fillColor,
      fillOpacity: override.fillOpacity ?? base.fillOpacity,
      borderColor: override.borderColor ?? base.borderColor,
      borderOpacity: override.borderOpacity ?? base.borderOpacity,
      borderWidth: override.borderWidth ?? base.borderWidth,
      foregroundColor: override.foregroundColor ?? base.foregroundColor,
      foregroundOpacity: override.foregroundOpacity ?? base.foregroundOpacity,
      shape: override.shape ?? base.shape,
      labelWeight: override.labelWeight ?? base.labelWeight,
    );
  }
}

/// Rich, partial card-surface styling: fill, border, heading/body text, and
/// button treatments. This is the single vocabulary every card surface in a
/// navigation tab resolves against — a community-level default, optionally
/// overridden per-tab, optionally overridden per-workflow. Every field is
/// nullable so any scope can override just the fields it cares about.
class LoomCardTheme {
  const LoomCardTheme({
    this.accent,
    this.fillColor,
    this.fillOpacity,
    this.borderColor,
    this.borderOpacity,
    this.borderWidth,
    this.headingColor,
    this.headingOpacity,
    this.headingWeight,
    this.bodyColor,
    this.bodyOpacity,
    this.cornerRadius,
    this.elevation,
    this.shadowOpacity,
    this.primaryButton,
    this.secondaryButton,
  });

  /// Formalizes the app's previous ad hoc `_foregroundFor`/
  /// `_screenBackgroundFor` brightness heuristics into named, overridable
  /// fields. When [neutralSurface] is true (the default) the card fill is a
  /// shared neutral dark tone rather than the accent itself — the accent is
  /// reserved for borders, headings, badges, and buttons so it reads as a
  /// highlight, not a block of color. When [lightSurface] is true (used for
  /// communities that opt into the modern card theme via an explicit
  /// `experience.theme` block), the fill instead matches
  /// `CommunityLaunchCard`'s light, subtle look — a faint accent tint over
  /// white, with fixed dark heading/body text — instead of the dark neutral.
  factory LoomCardTheme.deriveFromAccent(
    Color accent, {
    bool neutralSurface = true,
    bool lightSurface = false,
  }) {
    if (lightSurface) {
      final onAccent = _foregroundFor(accent);
      return LoomCardTheme(
        accent: accent,
        fillColor: Color.alphaBlend(accent.withValues(alpha: 0.07), Colors.white),
        fillOpacity: 1.0,
        borderColor: accent,
        borderOpacity: 0.16,
        borderWidth: 1,
        headingColor: const Color(0xff172421),
        headingOpacity: 1.0,
        headingWeight: FontWeight.w800,
        bodyColor: const Color(0xff43534f),
        bodyOpacity: 0.82,
        cornerRadius: 16,
        elevation: 3,
        shadowOpacity: 0.12,
        primaryButton: LoomButtonTheme(
          fillColor: accent,
          fillOpacity: 1.0,
          borderColor: accent,
          borderOpacity: 1.0,
          borderWidth: 0,
          foregroundColor: onAccent,
          foregroundOpacity: 1.0,
          shape: LoomButtonShape.pill,
          labelWeight: FontWeight.w700,
        ),
        secondaryButton: LoomButtonTheme(
          fillColor: accent,
          fillOpacity: 0.12,
          borderColor: accent,
          borderOpacity: 0.4,
          borderWidth: 1,
          foregroundColor: accent,
          foregroundOpacity: 1.0,
          shape: LoomButtonShape.pill,
          labelWeight: FontWeight.w600,
        ),
      );
    }
    final fill = neutralSurface ? _neutralCardFill : accent;
    final onFill = _foregroundFor(fill);
    final onAccent = _foregroundFor(accent);
    return LoomCardTheme(
      accent: accent,
      fillColor: fill,
      fillOpacity: 1.0,
      borderColor: accent,
      borderOpacity: 0.34,
      borderWidth: 1,
      headingColor: onFill,
      headingOpacity: 1.0,
      headingWeight: FontWeight.w800,
      bodyColor: onFill,
      bodyOpacity: 0.82,
      cornerRadius: 16,
      elevation: 3,
      shadowOpacity: 0.24,
      primaryButton: LoomButtonTheme(
        fillColor: accent,
        fillOpacity: 1.0,
        borderColor: accent,
        borderOpacity: 1.0,
        borderWidth: 0,
        foregroundColor: onAccent,
        foregroundOpacity: 1.0,
        shape: LoomButtonShape.pill,
        labelWeight: FontWeight.w700,
      ),
      secondaryButton: LoomButtonTheme(
        fillColor: accent,
        fillOpacity: 0.12,
        borderColor: accent,
        borderOpacity: 0.4,
        borderWidth: 1,
        foregroundColor: accent,
        foregroundOpacity: 1.0,
        shape: LoomButtonShape.pill,
        labelWeight: FontWeight.w600,
      ),
    );
  }

  final Color? accent;
  final Color? fillColor;
  final double? fillOpacity;
  final Color? borderColor;
  final double? borderOpacity;
  final double? borderWidth;
  final Color? headingColor;
  final double? headingOpacity;
  final FontWeight? headingWeight;
  final Color? bodyColor;
  final double? bodyOpacity;
  final double? cornerRadius;
  final double? elevation;
  final double? shadowOpacity;
  final LoomButtonTheme? primaryButton;
  final LoomButtonTheme? secondaryButton;

  Color get resolvedFill =>
      (fillColor ?? _neutralCardFill).withValues(alpha: fillOpacity ?? 1.0);
  Color get resolvedBorder => (borderColor ?? accent ?? Colors.white)
      .withValues(alpha: borderOpacity ?? 0.34);
  Color get resolvedHeading =>
      (headingColor ?? Colors.white).withValues(alpha: headingOpacity ?? 1.0);
  Color get resolvedBody =>
      (bodyColor ?? Colors.white).withValues(alpha: bodyOpacity ?? 0.82);
  Color get resolvedShadow => (accent ?? borderColor ?? Colors.black)
      .withValues(alpha: shadowOpacity ?? 0.24);

  /// Merges [override] onto [base]. Unset fields on [override] inherit from
  /// [base]. If [override] declares a different `accent` than [base], the
  /// base is first re-derived from that new accent (via
  /// [LoomCardTheme.deriveFromAccent]) before the field-by-field merge, so
  /// declaring just `{"accent": "#..."}` at a tab or workflow level produces
  /// a fully coherent re-theme instead of a stale mix of old and new colors.
  /// Any other explicit field on [override] still wins over the re-derived
  /// value.
  static LoomCardTheme merge(LoomCardTheme base, LoomCardTheme? override) {
    if (override == null) return base;
    final accentChanged =
        override.accent != null && override.accent != base.accent;
    final baseIsLight = base.fillColor != null &&
        ThemeData.estimateBrightnessForColor(base.fillColor!) ==
            Brightness.light;
    final effectiveBase = accentChanged
        ? LoomCardTheme.deriveFromAccent(
            override.accent!,
            neutralSurface: base.fillColor != base.accent,
            lightSurface: baseIsLight,
          )
        : base;
    return LoomCardTheme(
      accent: override.accent ?? effectiveBase.accent,
      fillColor: override.fillColor ?? effectiveBase.fillColor,
      fillOpacity: override.fillOpacity ?? effectiveBase.fillOpacity,
      borderColor: override.borderColor ?? effectiveBase.borderColor,
      borderOpacity: override.borderOpacity ?? effectiveBase.borderOpacity,
      borderWidth: override.borderWidth ?? effectiveBase.borderWidth,
      headingColor: override.headingColor ?? effectiveBase.headingColor,
      headingOpacity: override.headingOpacity ?? effectiveBase.headingOpacity,
      headingWeight: override.headingWeight ?? effectiveBase.headingWeight,
      bodyColor: override.bodyColor ?? effectiveBase.bodyColor,
      bodyOpacity: override.bodyOpacity ?? effectiveBase.bodyOpacity,
      cornerRadius: override.cornerRadius ?? effectiveBase.cornerRadius,
      elevation: override.elevation ?? effectiveBase.elevation,
      shadowOpacity: override.shadowOpacity ?? effectiveBase.shadowOpacity,
      primaryButton: LoomButtonTheme.merge(
        effectiveBase.primaryButton,
        override.primaryButton,
      ),
      secondaryButton: LoomButtonTheme.merge(
        effectiveBase.secondaryButton,
        override.secondaryButton,
      ),
    );
  }
}

/// Community-wide surface theme: the plain accent-driven chrome (AppBar,
/// hero card, bottom tab bar) plus the resolved [LoomCardTheme] cascade for
/// the currently-selected tab.
class LoomSurfaceTheme {
  const LoomSurfaceTheme({
    required this.accent,
    required this.background,
    required this.tabHeight,
    required this.density,
    required this.imageTreatment,
    required this.communityCard,
    required this.tabCard,
    required this.usesModernCardTheme,
  });

  final Color accent;
  final Color background;
  final double tabHeight;
  final String density;
  final String imageTreatment;

  /// True when this community declared an explicit `experience.theme` block
  /// (package-driven, opted in). Gates every card surface's switch to the
  /// light/modern card treatment — every other (bespoke catalog) community
  /// renders with zero visual change from before this cascade existed.
  final bool usesModernCardTheme;

  /// Community-level default card theme (accent + `experience.theme`
  /// override merged on top).
  final LoomCardTheme communityCard;

  /// [communityCard] merged with the current tab's `tabThemes` override, if
  /// any. This is what tiles/action surfaces in the selected tab resolve
  /// against by default, before any per-workflow override.
  final LoomCardTheme tabCard;
}
