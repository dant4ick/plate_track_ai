import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? titleText;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onRefresh;
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
    this.onRefresh,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> appBarActions = [];
    
    // Add refresh button if callback is provided
    if (onRefresh != null) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'refresh'.tr(),
        ),
      );
    }
    
    // Add any additional actions
    if (actions != null) {
      appBarActions.addAll(actions!);
    }

    return AppBar(
      title: showLogo 
          ? (titleText != null 
              ? AppLogoWithText(
                  text: titleText!,
                  logoSize: 24,
                  fontSize: 18,
                )
              : const AppLogoWithText())
          : (titleText != null ? Text(titleText!) : null),
      elevation: 0,
      actions: appBarActions.isNotEmpty ? appBarActions : null,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}
