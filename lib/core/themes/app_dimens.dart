import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Geometry and elevation tokens for the design system.
///
/// Colour lives in [AppColors]; everything that is a *measurement* lives here,
/// so the rounding of a card and the rounding of the button inside it cannot
/// drift apart. Widgets should reference these instead of literal numbers.
class AppDimens {
  AppDimens._();

  // ── Radii ──────────────────────────────────────────────────────────────────

  /// Cards and other large surfaces.
  static const double radiusCard = 20.0;

  /// Buttons, inputs, thumbnails — anything nested inside a card, kept a step
  /// tighter than [radiusCard] so concentric corners look concentric.
  static const double radiusControl = 14.0;

  /// Image thumbnails inside a list row.
  static const double radiusThumb = 16.0;

  /// The squircle used by the logo mark and the floating action button.
  static const double radiusSquircle = 22.0;

  /// Fully round — pills, chips, progress bars.
  static const double radiusPill = 999.0;

  // ── Spacing ────────────────────────────────────────────────────────────────

  /// Page gutter.
  static const double gutter = 16.0;

  /// Padding inside a card.
  static const double cardPadding = 18.0;

  /// Gap between a section header and its card.
  static const double headerGap = 10.0;

  /// Gap between two sections.
  static const double sectionGap = 22.0;

  // ── Strokes ────────────────────────────────────────────────────────────────

  /// Thickness of the semicircular calorie gauge.
  static const double gaugeStroke = 26.0;

  /// Thickness of the weight-progress ring.
  static const double ringStroke = 7.0;

  /// Height of a macro progress bar.
  static const double macroBarHeight = 9.0;

  // ── Elevation ──────────────────────────────────────────────────────────────

  /// The card lift: a wide ambient halo that separates the card from the page,
  /// plus a tight contact shadow at its lower edge.
  ///
  /// The ambient layer keeps `spreadRadius` at zero so the blur reaches around
  /// all four sides. Pulling it negative confines the shadow to the strip below
  /// the card, which reads as a hairline rule rather than a lift.
  static List<BoxShadow> cardShadow(AppPalette palette) => [
    BoxShadow(
      color: palette.shadowCardAmbient,
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: palette.shadowCardContact,
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(radiusCard);

  // ── System insets ──────────────────────────────────────────────────────────

  /// Padding for a scrolling page, with the bottom grown by the system
  /// navigation inset.
  ///
  /// Android 15 and up render apps edge to edge, so a scroll view's last child
  /// otherwise comes to rest underneath the navigation bar. Scroll views take
  /// *padding* rather than a `SafeArea`: a `SafeArea` shrinks the viewport, so
  /// content could never travel through the inset region at all, whereas padding
  /// lets it scroll under the bar and still settle above it.
  ///
  /// [bottom] is the gap wanted above the inset — raise it on pages with a
  /// floating action button to clear that too.
  static EdgeInsets pagePadding(BuildContext context, {double bottom = gutter}) {
    return EdgeInsets.fromLTRB(
      gutter,
      gutter,
      gutter,
      bottom + MediaQuery.paddingOf(context).bottom,
    );
  }
}
