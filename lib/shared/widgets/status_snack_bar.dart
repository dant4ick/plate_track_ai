import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// Status messages share a theme-resolved background and readable foreground.
abstract final class StatusSnackBar {
  static SnackBar success(
    BuildContext context, {
    required String message,
    IconData? icon,
  }) => _build(context, message, AppPalette.of(context).success, icon);

  static SnackBar error(BuildContext context, {required String message}) =>
      _build(context, message, AppPalette.of(context).danger, null);

  static SnackBar _build(
    BuildContext context,
    String message,
    Color background,
    IconData? icon,
  ) {
    final foreground = AppPalette.of(context).foregroundOn(background);
    return SnackBar(
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusControl),
      ),
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    );
  }
}
