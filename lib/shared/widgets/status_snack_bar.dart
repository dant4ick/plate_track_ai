import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// Neutral success cards use the brand accent; errors keep their danger fill.
abstract final class StatusSnackBar {
  static SnackBar success(
    BuildContext context, {
    required String message,
    IconData? icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SnackBar(
      backgroundColor: scheme.surface,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusCard),
        side: BorderSide(color: AppPalette.of(context).border),
      ),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(AppDimens.radiusControl),
            ),
            child: Icon(
              icon ?? Icons.check_circle,
              color: scheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: scheme.onSurface)),
          ),
        ],
      ),
    );
  }

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
