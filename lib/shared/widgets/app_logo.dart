import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogo({
    Key? key,
    this.size = 24,
    this.color,
  }) : super(key: key);

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
      semanticsLabel: 'Plate Track AI Logo',
    );
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
    Key? key,
    this.logoSize = 28,
    this.fontSize = 20,
    this.logoColor,
    this.textColor,
    this.text = 'Plate Track',
    this.fontWeight = FontWeight.w600,
    this.alignment = MainAxisAlignment.center,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: logoSize,
          color: logoColor,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
