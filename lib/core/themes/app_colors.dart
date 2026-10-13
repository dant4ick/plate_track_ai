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

  /// Primary brand color. Drives the dark theme (FAB, headings, accents).
  static const Color prime = Color(0xFF4D55F5);

  /// Secondary accent (lime). Drives the light theme.
  static const Color second = Color(0xFFDAFF7C);

  /// Tertiary accent.
  static const Color tri = Color(0xFFCA7FFE);

  // ── Brand shades ───────────────────────────────────────────────────────────
  // Derived from the three brand hues so brand color can also be used where
  // the raw token would fail contrast (text, icons, filled buttons).

  /// Readable shade of [second]; the light theme's primary (FAB, nav, links).
  static const Color secondShade = Color(0xFFA3D65B);

  /// Deep shade of [second], for text sitting on [secondSoft].
  static const Color secondDeep = Color(0xFF6E9B2E);

  /// Lime tint used as a card/banner fill in the light theme.
  static const Color secondSoft = Color(0xFFEFFAD6);

  /// Lighter shade of [prime], for text/icons on dark surfaces.
  static const Color primeShade = Color(0xFF7B82F8);

  /// Navy tint used as a card/banner fill in the dark theme.
  static const Color primeSoft = Color(0xFF1B2145);

  /// Readable shade of [tri], for tertiary accents on light surfaces.
  static const Color triShade = Color(0xFF8E3FD6);

  // ── "Pick me" ──────────────────────────────────────────────────────────────
  // Third brand hue, driving the pink theme frame.

  /// Primary of the pick-me theme — headings, section labels, calorie figures.
  static const Color pick = Color(0xFFF2557B);

  /// Softer pink for text sitting on [pickSoft], where [pick] reads too heavy.
  static const Color pickMuted = Color(0xFFF589A5);

  /// Pink tint used as a card/banner fill in the pick-me theme.
  static const Color pickSoft = Color(0xFFFADCE6);

  /// Filled app-bar band. Light and dark keep a flat surface here; pink
  /// tints it, so the app bar is the one surface that is not theme-neutral.
  static const Color pickBar = Color(0xFFF9C8DA);

  /// Calorie progress fill in the pick-me theme.
  static const Color pickCalories = Color(0xFFF04A78);

  // ───────────────────────────────────────────────────────────────────────────
  // Macronutrients
  // ───────────────────────────────────────────────────────────────────────────
  // Each macro carries three roles, because one hue cannot serve all of them:
  //
  //  * plain name  — the *graphic* colour: bars, gauge segments, pie slices,
  //    legend swatches. Tuned for vividness to match the design, and never
  //    used for text: at these luminances the pastel-adjacent hues would fail
  //    contrast on a white card.
  //  * `...Ink`    — the *text* colour: chip labels, figures, anything read as
  //    type. Every Ink/Soft pair clears 4.5:1, in both brightnesses.
  //  * `...Soft`   — the pale chip/pill fill the matching Ink sits on.
  //
  // Bars deliberately do not clear 3:1 against a white card: every bar in the
  // design prints its gram value directly above it, so the bar is redundant
  // decoration rather than the sole carrier of the value.

  /// Protein graphic — bars, slices, swatches.
  static const Color protein = Color(0xFFD14FDE);

  /// Protein text on [proteinSoft] or a light card.
  static const Color proteinInk = Color(0xFFA32DB4);

  /// Protein text on [proteinSoftDark] or a dark card.
  static const Color proteinInkDark = Color(0xFFE68BEF);

  /// Protein chip fill (light).
  static const Color proteinSoft = Color(0xFFFBE7FD);

  /// Carbohydrate graphic — bars, slices, swatches.
  static const Color carbs = Color(0xFFF5A623);

  /// Carbohydrate text on [carbsSoft] or a light card.
  static const Color carbsInk = Color(0xFF9A6200);

  /// Carbohydrate text on [carbsSoftDark] or a dark card.
  static const Color carbsInkDark = Color(0xFFF0A62E);

  /// Carbohydrate chip fill (light).
  static const Color carbsSoft = Color(0xFFFFF3E0);

  /// Fat graphic — bars, slices, swatches.
  static const Color fat = Color(0xFF46A6E8);

  /// Fat text on [fatSoft] or a light card.
  static const Color fatInk = Color(0xFF16719F);

  /// Fat text on [fatSoftDark] or a dark card.
  static const Color fatInkDark = Color(0xFF58B4F5);

  /// Fat chip fill (light).
  static const Color fatSoft = Color(0xFFE4F2FD);

  /// Calories graphic — the coral of the dashboard gauge.
  static const Color calories = Color(0xFFE8615A);

  /// Calories graphic on dark surfaces.
  static const Color caloriesDark = Color(0xFFE8446B);

  /// Calories text on [caloriesSoft] or a light card.
  static const Color caloriesInk = Color(0xFFC0342D);

  /// Calories text on a dark card.
  static const Color caloriesInkDark = Color(0xFFFC8C86);

  /// Calories chip fill (light).
  static const Color caloriesSoft = Color(0xFFFDECEC);

  // The pale fills above are tuned for light surfaces. On a dark card they read
  // as bright patches, so each is replaced by an 18% wash of its own graphic
  // colour — the value the matching `...InkDark` was contrast-checked against.
  static const Color proteinSoftDark = Color(0x2ED14FDE);
  static const Color carbsSoftDark = Color(0x2EF5A623);
  static const Color fatSoftDark = Color(0x2E46A6E8);
  static const Color caloriesSoftDark = Color(0x2EE8615A);

  // ───────────────────────────────────────────────────────────────────────────
  // Status
  // ───────────────────────────────────────────────────────────────────────────

  static const Color successLight = Color(0xFF43A047);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color successSoftLight = Color(0xFFE8F5E9);
  static const Color successSoftDark = Color(0x3327632A);

  static const Color warningLight = Color(0xFFEF8E1B);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color warningSoftLight = Color(0xFFFFF4E0);
  static const Color warningSoftDark = Color(0x337A4A00);
  static const Color warningBorderLight = Color(0xFFFFCC80);
  static const Color warningBorderDark = Color(0xFFB06E10);
  static const Color warningTextLight = Color(0xFF8A5200);
  static const Color warningTextDark = Color(0xFFFFD9A0);

  static const Color dangerLight = Color(0xFFE04A4A);
  static const Color dangerDark = Color(0xFFEF7A7A);
  static const Color dangerSoftLight = Color(0xFFFDECEC);
  static const Color dangerSoftDark = Color(0x33A02020);
  static const Color dangerBorderLight = Color(0xFFF3B4B4);
  static const Color dangerBorderDark = Color(0xFFB53F3F);

  static const Color infoLight = Color(0xFF2E86C1);
  static const Color infoDark = Color(0xFF64B5F6);

  // ───────────────────────────────────────────────────────────────────────────
  // Surfaces
  // ───────────────────────────────────────────────────────────────────────────

  static const Color scaffoldLight = Color(0xFFFFFFFF);
  static const Color scaffoldDark = Color(0xFF0D0D14);

  /// Faintly pink page background — the pick-me theme's scaffold is not white.
  static const Color scaffoldPick = Color(0xFFFDF5F8);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2A2A2A);

  static const Color appBarLight = Color(0xFFFCFCFC);
  static const Color appBarDark = Color(0xFF0D0D14);

  /// Fill for inputs and other inset "well" areas.
  static const Color fieldLight = Color(0xFFF4F5F7);
  static const Color fieldDark = Color(0xFF1E1E24);

  /// Camera / scanner chrome. Fixed regardless of theme — it sits on a live
  /// camera preview, never on a themed surface.
  static const Color cameraBackdrop = Color(0xFF000000);
  static const Color cameraPanel = Color(0x8A000000);
  static const Color cameraPanelSoft = Color(0x42000000);
  static const Color cameraMask = Color(0x8C000000);
  static const Color cameraForeground = Color(0xFFFFFFFF);

  // ───────────────────────────────────────────────────────────────────────────
  // Content — text, icons, dividers
  // ───────────────────────────────────────────────────────────────────────────

  static const Color textPrimaryLight = Color(0xDD000000);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9AA0A6);

  static const Color textTertiaryLight = Color(0xFF9CA3AF);
  static const Color textTertiaryDark = Color(0xFF6B7280);

  /// Foreground on top of a filled brand/status surface.
  static const Color onAccent = Color(0xFFFFFFFF);

  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF3A3A42);

  /// Unfilled portion of progress bars and sliders.
  static const Color trackLight = Color(0xFFE8E8E8);
  static const Color trackDark = Color(0xFF3A3A42);

  /// Neutral fill for placeholder/empty-state blocks.
  static const Color placeholderLight = Color(0xFFF1F2F4);
  static const Color placeholderDark = Color(0xFF26262E);

  /// Icon on a placeholder/empty-state block.
  static const Color placeholderIconLight = Color(0xFFB0B4BB);
  static const Color placeholderIconDark = Color(0xFF7A7F87);

  /// Inactive bottom-nav item.
  static const Color navInactiveLight = Color(0xFF9E9E9E);
  static const Color navInactiveDark = Color(0xFF8A8F98);

  // ───────────────────────────────────────────────────────────────────────────
  // Elevation & overlays
  // ───────────────────────────────────────────────────────────────────────────

  /// Card / nav-bar drop shadow.
  static const Color shadowSoft = Color(0x1A000000);
  static const Color shadowMedium = Color(0x1F000000);
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

  /// Anything read as type. Clears 4.5:1 against [fill].
  final Color ink;

  /// The pale pill/chip background [ink] sits on.
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
  const AppPalette._(this.flavor);

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
    );
  }

  final AppFlavor flavor;

  bool get isDark => flavor == AppFlavor.dark;

  // Brand
  Color get brandSoft => switch (flavor) {
    AppFlavor.light => AppColors.secondSoft,
    AppFlavor.dark => AppColors.primeSoft,
    AppFlavor.pickMe => AppColors.pickSoft,
  };

  Color get onBrandSoft => switch (flavor) {
    AppFlavor.light => AppColors.secondDeep,
    AppFlavor.dark => AppColors.prime,
    AppFlavor.pickMe => AppColors.pickMuted,
  };

  // Status
  Color get success => isDark ? AppColors.successDark : AppColors.successLight;
  Color get successSoft =>
      isDark ? AppColors.successSoftDark : AppColors.successSoftLight;

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
  Color get dangerBorder =>
      isDark ? AppColors.dangerBorderDark : AppColors.dangerBorderLight;

  Color get info => isDark ? AppColors.infoDark : AppColors.infoLight;

  /// Calories accent for the current theme.
  Color get calories => switch (flavor) {
    AppFlavor.light => AppColors.calories,
    AppFlavor.dark => AppColors.caloriesDark,
    AppFlavor.pickMe => AppColors.pickCalories,
  };

  // Macronutrient chip/card fills for the current theme. The graphic colours
  // (`AppColors.protein` and friends) are brightness-independent; the Ink
  // colours are not, so they resolve through here.
  Color get proteinFill =>
      isDark ? AppColors.proteinSoftDark : AppColors.proteinSoft;
  Color get carbsFill => isDark ? AppColors.carbsSoftDark : AppColors.carbsSoft;
  Color get fatFill => isDark ? AppColors.fatSoftDark : AppColors.fatSoft;
  Color get caloriesFill =>
      isDark ? AppColors.caloriesSoftDark : AppColors.caloriesSoft;

  // Macronutrient text colours for the current theme. Use these wherever the
  // macro colour is read as type; use the `AppColors` graphic tokens for bars,
  // slices and swatches.
  Color get proteinInk =>
      isDark ? AppColors.proteinInkDark : AppColors.proteinInk;
  Color get carbsInk => isDark ? AppColors.carbsInkDark : AppColors.carbsInk;
  Color get fatInk => isDark ? AppColors.fatInkDark : AppColors.fatInk;
  Color get caloriesInk =>
      isDark ? AppColors.caloriesInkDark : AppColors.caloriesInk;

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
  Color get textTertiary =>
      isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
  Color get border => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color get track => isDark ? AppColors.trackDark : AppColors.trackLight;
  Color get placeholder =>
      isDark ? AppColors.placeholderDark : AppColors.placeholderLight;
  Color get placeholderIcon =>
      isDark ? AppColors.placeholderIconDark : AppColors.placeholderIconLight;
  Color get navInactive =>
      isDark ? AppColors.navInactiveDark : AppColors.navInactiveLight;

  /// Selected bottom-nav item. Lime in the light and dark frames, so it does
  /// not simply track `colorScheme.primary` (which is indigo in the dark).
  ///
  /// The pink frame renders no nav items at all, so its value is a guess:
  /// pink, to match its primary. Switch to [AppColors.secondShade] if the
  /// lime is meant to carry across all three themes.
  Color get navActive => switch (flavor) {
    AppFlavor.light => AppColors.secondShade,
    AppFlavor.dark => AppColors.second,
    AppFlavor.pickMe => AppColors.pick,
  };

  /// Drop shadow under cards and floating surfaces.
  Color get shadow => isDark ? AppColors.shadowStrong : AppColors.shadowSubtle;

  /// Wide ambient half of the card lift.
  Color get shadowCardAmbient => isDark
      ? AppColors.shadowCardAmbientDark
      : AppColors.shadowCardAmbient;

  /// Tight contact half of the card lift.
  Color get shadowCardContact => isDark
      ? AppColors.shadowCardContactDark
      : AppColors.shadowCardContact;

  /// Gridlines and other faint chart chrome.
  Color get chartGrid => isDark ? AppColors.borderDark : AppColors.borderLight;

  /// Low-emphasis wash of an accent, for the tinted pill/badge behind it.
  Color fillOf(Color accent) => accent.withValues(alpha: isDark ? 0.18 : 0.1);
  Color get field => isDark ? AppColors.fieldDark : AppColors.fieldLight;
}
