import 'package:flutter/material.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final bool showLogo;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;

  const StandardAppBar({
    super.key,
    this.titleText,
    this.showLogo = true,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle =
        Theme.of(context).appBarTheme.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge;
    return AppBar(
      titleSpacing: 16,
      scrolledUnderElevation: 0,
      title: showLogo
          ? (titleText != null
                ? AppLogoWithText(text: titleText!, logoSize: 24, fontSize: 18)
                : const AppLogoWithText())
          : (titleText != null ? Text(titleText!) : null),
      elevation: 0,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      // Explicit chrome colours (camera panels) must override every inherited
      // foreground role: AppBar.foregroundColor alone is only a fallback.
      titleTextStyle: foregroundColor == null
          ? null
          : titleStyle?.copyWith(color: foregroundColor),
      iconTheme: foregroundColor == null
          ? null
          : IconThemeData(color: foregroundColor),
      actionsIconTheme: foregroundColor == null
          ? null
          : IconThemeData(color: foregroundColor),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
