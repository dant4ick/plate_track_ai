import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';

/// The ordinary page canvas. Camera/scanner routes deliberately use Scaffold
/// directly: their fixed black chrome and live overlays are not themed pages.
///
/// Paint outside the Scaffold so the gradient spans the app bar, body, footer
/// and system insets, independently of scrolling content or keyboard resizing.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final isDark = AppPalette.of(context).isDark;
    final scaffold = Scaffold(
      backgroundColor: isDark ? Colors.transparent : null,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
    if (!isDark) return scaffold;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.scaffoldDark, AppColors.scaffoldDarkBottom],
        ),
      ),
      child: scaffold,
    );
  }
}
