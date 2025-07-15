import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';

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
      colorFilter:
          color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
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
    super.key,
    this.logoSize = 28,
    this.fontSize = 20,
    this.logoColor,
    this.textColor,
    this.text = 'app_name',
    this.fontWeight = FontWeight.w600,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(size: logoSize, color: logoColor),
        const SizedBox(width: 8),
        Text(
          text.tr(),
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
