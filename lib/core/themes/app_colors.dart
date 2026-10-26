import 'package:flutter/material.dart';

/// Color tokens for the "Plate Track mobile app screens" design system.
///
/// Every color used by the app lives here. Widgets must reference these tokens
/// (or `Theme.of(context).colorScheme` / [AppPalette]) instead of hard-coding
/// `Color(0x...)` or reaching for the Material `Colors.*` swatches.
///
/// Naming:
///  * plain name          — brand token, taken 1:1 from the Figma variables.
///  * `...Light` / `...Dark` — the two ends of a brightness-dependent pair.
///    Resolve those through [AppPalette] rather than checking brightness
///    at the call site.
///  * `...Soft`           — low-emphasis fill/container tint of an accent,
///    meant for backgrounds behind the matching accent used as foreground.
class AppColors {
  AppColors._();

  // ───────────────────────────────────────────────────────────────────────────
  // Brand — 1:1 with the Figma color variables
  // ───────────────────────────────────────────────────────────────────────────

  /// Blue brand colour, used as the light/dark theme secondary.
  static const Color prime = Color(0xFF4D55F5);

  /// Pale lime accent of the dark theme and glyph on the blue logo.
  static const Color second = Color(0xFFDAFF7C);

  /// Shared primary in every theme, matching the green logo tile.
  static const Color secondLight = Color(0xFFB0DD4E);

  /// Tertiary accent.
  static const Color tri = Color(0xFFCA7FFE);

  // ── Brand shades ───────────────────────────────────────────────────────────
  // Derived from the three brand hues so brand color can also be used where
  // the raw token would fail contrast (text, icons, filled buttons).

  /// Lime shade for filled controls; pair with [onAccentDark].
  static const Color secondShade = Color(0xFFA3D65B);

  /// Readable shade of [tri], for tertiary accents on light surfaces.
  static const Color triShade = Color(0xFF8E3FD6);

  // ── "Pick me" ──────────────────────────────────────────────────────────────
  // Third brand hue, driving the pink theme frame.

  /// Secondary of the pick-me theme, independent of the calorie colour.
  static const Color pick = Color(0xFFFF7AB5);

  // ───────────────────────────────────────────────────────────────────────────
  // Macronutrients
  // ───────────────────────────────────────────────────────────────────────────
  // One unchanged colour per macro for graphics, text and icons in every
  // theme. Macro backgrounds use neutral surfaces, not tinted variants.
  // These original hues do not guarantee 4.5:1 text contrast on light cards.

  /// Protein graphic — bars, slices, swatches.
  static const Color protein = Color(0xFFFF7777);

  /// Carbohydrate graphic — bars, slices, swatches.
  static const Color carbs = Color(0xFFFFCC77);

  /// Fat graphic — bars, slices, swatches.
  static const Color fat = Color(0xFFAF5BD0);
  static const Color calories = Color(0xFFFF3372);

  // ───────────────────────────────────────────────────────────────────────────
  // Status
  // ───────────────────────────────────────────────────────────────────────────

  static const Color successLight = Color(0xFF43A047);
  static const Color successDark = Color(0xFF66BB6A);

  static const Color warningLight = Color(0xFFEF8E1B);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color warningSoftLight = Color(0xFFFFF3E0);
  static const Color warningSoftDark = Color(0x337A4A00);
  static const Color warningBorderLight = Color(0xFFFFCC80);
  static const Color warningBorderDark = Color(0xFFB06E10);
  static const Color warningTextLight = Color(0xFF8A5200);
  static const Color warningTextDark = Color(0xFFFFD9A0);

  static const Color dangerLight = Color(0xFFE04A4A);
  static const Color dangerDark = Color(0xFFEF7A7A);
  static const Color dangerSoftLight = Color(0xFFFDECEC);
  static const Color dangerSoftDark = Color(0x33A02020);

  static const Color infoLight = Color(0xFF2E86C1);
  static const Color infoDark = Color(0xFF64B5F6);

  // ───────────────────────────────────────────────────────────────────────────
  // Surfaces
  // ───────────────────────────────────────────────────────────────────────────

  static const Color scaffoldLight = Color(0xFFFFFFFF);
  static const Color scaffoldDark = Color(0xFF1A191F);

  /// Faintly pink page background — the pick-me theme's scaffold is not white.
  static const Color scaffoldPick = Color(0xFFFFF6F9);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF262A35);

  /// Fill for inputs and other inset "well" areas.
  static const Color fieldLight = Color(0xFFF4F5F7);
  static const Color fieldDark = Color(0xFF1E1E24);

  /// Camera / scanner chrome. Fixed regardless of theme — it sits on a live
  /// camera preview, never on a themed surface.
  static const Color cameraBackdrop = Color(0xFF000000);
  static const Color cameraPanel = Color(0x8A000000);
  static const Color cameraPanelSoft = Color(0x42000000);
  static const Color cameraMask = cameraPanel;
  static const Color cameraForeground = Color(0xFFFFFFFF);

  // ───────────────────────────────────────────────────────────────────────────
  // Content — text, icons, dividers
  // ───────────────────────────────────────────────────────────────────────────

  static const Color textPrimaryLight = Color(0xDD000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9AA0A6);

  /// Foreground on a dark filled accent.
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Foreground on a light filled accent, including lime and status colours.
  static const Color onAccentDark = Color(0xFF000000);

  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF3A3A42);

  /// Unfilled portion of progress bars and sliders.
  static const Color trackLight = borderLight;
  static const Color trackDark = Color(0xFF3A3A42);

  /// Neutral fill for placeholder/empty-state blocks.
  static const Color placeholderLight = fieldLight;
  static const Color placeholderDark = Color(0xFF26262E);

  /// Icon on a placeholder/empty-state block.
  static const Color placeholderIconLight = Color(0xFFB0B4BB);
  static const Color placeholderIconDark = Color(0xFF7A7F87);

  // ───────────────────────────────────────────────────────────────────────────
  // Elevation & overlays
  // ───────────────────────────────────────────────────────────────────────────

  /// Card / nav-bar drop shadow.
  static const Color shadowSubtle = Color(0x14000000);

  static const Color shadowStrong = Color(0x33000000);

  /// Card lift. Two layers: a wide ambient wash plus a tight contact shadow.
  /// Kept separate from [shadowSubtle] because a wide blur needs more alpha than
  /// a tight one to register at all.
  static const Color shadowCardAmbient = Color(0x14000000);
  static const Color shadowCardContact = Color(0x0F000000);

  /// The same pair on a dark scaffold, where the card is lighter than the page
  /// and the shadow has to work harder to separate them.
  static const Color shadowCardAmbientDark = Color(0x5C000000);
  static const Color shadowCardContactDark = Color(0x3D000000);

  /// Full-screen dim behind the expanded speed-dial.
  static const Color scrim = Color(0x73000000);
}

/// The four tracked quantities that carry their own hue.
enum Macro { protein, carbs, fat, calories }

/// The three colour roles one [Macro] plays, already resolved for a theme.
@immutable
class MacroStyle {
  const MacroStyle({
    required this.graphic,
    required this.ink,
    required this.fill,
  });

  /// Bars, gauge segments, pie slices, legend swatches.
  final Color graphic;

  /// Text and icons use the original nutrition hue, without contrast shading.
  final Color ink;

  /// Neutral pill/chip surface behind [ink].
  final Color fill;
}

/// The brand identities the app ships. [AppFlavor.light] and [AppFlavor.dark]
/// differ in brightness; [AppFlavor.pickMe] is a light theme with its own hue,
/// which is why brightness alone can no longer identify a theme.
enum AppFlavor { light, dark, pickMe }

/// Carries the active [AppFlavor] on the [ThemeData], so [AppPalette] can tell
/// the two light themes apart without any app-level state.
@immutable
class AppFlavorTag extends ThemeExtension<AppFlavorTag> {
  const AppFlavorTag(this.flavor);

  final AppFlavor flavor;

  @override
  AppFlavorTag copyWith({AppFlavor? flavor}) =>
      AppFlavorTag(flavor ?? this.flavor);

  /// A flavor is an identity, not a scale, so it snaps at the midpoint of a
  /// theme transition rather than interpolating.
  @override
  AppFlavorTag lerp(ThemeExtension<AppFlavorTag>? other, double t) =>
      t < 0.5 ? this : (other as AppFlavorTag? ?? this);
}

/// Resolves the theme-dependent tokens in [AppColors] for the current theme,
/// so widgets never branch on `Theme.of(context).brightness` themselves.
///
/// ```dart
/// final palette = AppPalette.of(context);
/// Text('…', style: TextStyle(color: palette.textSecondary));
/// ```
///
/// Most tokens vary only by brightness, so they branch on [isDark] and the
/// pick-me theme inherits the light value. Only tokens the pink frame actually
/// restyles switch on [flavor].
class AppPalette {
  const AppPalette._(this.flavor, this._scheme);

  /// Reads the active flavor off the theme, falling back to brightness for any
  /// [ThemeData] built without an [AppFlavorTag].
  factory AppPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final tag = theme.extension<AppFlavorTag>();
    return AppPalette._(
      tag?.flavor ??
          (theme.brightness == Brightness.dark
              ? AppFlavor.dark
              : AppFlavor.light),
      theme.colorScheme,
    );
  }

  final AppFlavor flavor;

  final ColorScheme _scheme;

  bool get isDark => flavor == AppFlavor.dark;

  /// Readable tertiary accent on the current card surface.
  Color get accentInk => isDark ? AppColors.tri : AppColors.triShade;

  /// The weight marker keeps its lime identity across the three themes.
  Color get weightAccent => AppColors.secondShade;

  /// Chooses the higher-contrast foreground for an opaque filled accent.
  /// Text/icons on lime, pink, status colours and pie slices need dark ink;
  /// indigo needs white. Resolve from the actual background, not brightness.
  Color foregroundOn(Color background) {
    final luminance = background.computeLuminance();
    final darkContrast = (luminance + 0.05) / 0.05;
    final lightContrast = 1.05 / (luminance + 0.05);
    return darkContrast >= lightContrast
        ? AppColors.onAccentDark
        : AppColors.onAccent;
  }

  // Status
  Color get success => isDark ? AppColors.successDark : AppColors.successLight;

  Color get warning => isDark ? AppColors.warningDark : AppColors.warningLight;
  Color get warningSoft =>
      isDark ? AppColors.warningSoftDark : AppColors.warningSoftLight;
  Color get warningBorder =>
      isDark ? AppColors.warningBorderDark : AppColors.warningBorderLight;
  Color get warningText =>
      isDark ? AppColors.warningTextDark : AppColors.warningTextLight;

  Color get danger => isDark ? AppColors.dangerDark : AppColors.dangerLight;
  Color get dangerSoft =>
      isDark ? AppColors.dangerSoftDark : AppColors.dangerSoftLight;

  Color get info => isDark ? AppColors.infoDark : AppColors.infoLight;

  /// Fixed calorie accent, independent of the theme primary.
  Color get calories => AppColors.calories;

  // Keep the existing role API, with neutral fills and original macro hues.
  Color get proteinFill => _scheme.surface;
  Color get carbsFill => _scheme.surface;
  Color get fatFill => _scheme.surface;
  Color get caloriesFill => _scheme.surface;

  Color get proteinInk => AppColors.protein;
  Color get carbsInk => AppColors.carbs;
  Color get fatInk => AppColors.fat;

  Color get caloriesInk => AppColors.calories;

  /// The three roles of one macro, resolved for the current theme, so a caller
  /// that renders a bar *and* its label does not have to pick two tokens by
  /// hand and risk mismatching them.
  MacroStyle styleOf(Macro macro) => switch (macro) {
    Macro.protein => MacroStyle(
      graphic: AppColors.protein,
      ink: proteinInk,
      fill: proteinFill,
    ),
    Macro.carbs => MacroStyle(
      graphic: AppColors.carbs,
      ink: carbsInk,
      fill: carbsFill,
    ),
    Macro.fat => MacroStyle(graphic: AppColors.fat, ink: fatInk, fill: fatFill),
    Macro.calories => MacroStyle(
      graphic: calories,
      ink: caloriesInk,
      fill: caloriesFill,
    ),
  };

  // Content
  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  Color get border => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color get track => isDark ? AppColors.trackDark : AppColors.trackLight;
  Color get placeholder =>
      isDark ? AppColors.placeholderDark : AppColors.placeholderLight;
  Color get placeholderIcon =>
      isDark ? AppColors.placeholderIconDark : AppColors.placeholderIconLight;

  /// Drop shadow under cards and floating surfaces.
  Color get shadow => isDark ? AppColors.shadowStrong : AppColors.shadowSubtle;

  /// Wide ambient half of the card lift.
  Color get shadowCardAmbient =>
      isDark ? AppColors.shadowCardAmbientDark : AppColors.shadowCardAmbient;

  /// Tight contact half of the card lift.
  Color get shadowCardContact =>
      isDark ? AppColors.shadowCardContactDark : AppColors.shadowCardContact;

  /// Gridlines and other faint chart chrome.
  Color get chartGrid => isDark ? AppColors.borderDark : AppColors.borderLight;

  /// Low-emphasis wash of an accent, for the tinted pill/badge behind it.
  Color fillOf(Color accent) => accent.withValues(alpha: isDark ? 0.18 : 0.1);
}
