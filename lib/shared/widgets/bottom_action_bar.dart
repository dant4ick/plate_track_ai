import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// A pinned footer of side-by-side actions — the cancel/save pair the result
/// screens end with.
///
/// Unlike a scrolling page, a pinned footer really must not enter the system
/// navigation area, so this one wraps itself in a `SafeArea`. `Scaffold` does
/// *not* do that for `bottomNavigationBar`: whatever is handed to it draws
/// wherever it is put, which on an edge-to-edge Android means underneath the
/// navigation bar.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.children});

  /// Actions laid out in a row, each given equal width.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        // A hairline separates the bar from content scrolling behind it.
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        // The footer only owns the bottom edge; the app bar handles the top.
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.gutter),
          child: Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: AppDimens.gutter),
                Expanded(child: children[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
