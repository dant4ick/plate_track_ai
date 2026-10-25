import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/app_icon.svg',
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : ColorFilter.mode(
              Theme.of(context).colorScheme.primary,
              BlendMode.srcIn,
            ),
    );
  }
}

/// The designer's complete tile, including its own padding and brand colours.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 34});

  /// Outer edge of the tile. Insets and corner shapes are part of the SVG.
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = switch (AppPalette.of(context).flavor) {
      AppFlavor.dark => 'assets/icons/app_icon_color.svg',
      AppFlavor.light => 'assets/icons/app_icon_light.svg',
      AppFlavor.pickMe => 'assets/icons/app_icon_pick_me.svg',
    };
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

class AppLogoWithText extends StatelessWidget {
  final double logoSize;
  final double fontSize;
  final Color? logoColor;
  final Color? textColor;
  final String text;
  final FontWeight fontWeight;
  final MainAxisAlignment alignment;

  const AppLogoWithText({
    super.key,
    this.logoSize = 28,
    this.fontSize = 20,
    this.logoColor,
    this.textColor,
    this.text = 'app_name',
    this.fontWeight = FontWeight.w600,
    this.alignment = MainAxisAlignment.center,
    this.boxed = true,
  });

  /// Render the glyph as a filled [AppLogoMark] tile (the design's treatment)
  /// rather than a bare tinted glyph.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (boxed && logoColor == null)
          AppLogoMark(size: logoSize * 1.25)
        else
          AppLogo(size: logoSize, color: logoColor),
        const SizedBox(width: 10),
        Text(
          text.tr(),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: -0.3,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
