import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';

Future<void> showDeleteConfirmationDialog({
  required BuildContext context,
  required FoodItem item,
  required Future<void> Function() onDeleteConfirmed,
  required String confirmationTextKey,
  required String undoWarningTextKey,
  required String successMessageKey,
  required String deleteButtonTextKey,
}) async {
  final palette = AppPalette.of(context);

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.dangerSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline,
                color: palette.danger,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'delete_food_item'.tr(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirmationTextKey,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: palette.warningBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: palette.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      undoWarningTextKey,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.warningText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await onDeleteConfirmed();
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.onAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(successMessageKey),
                      ],
                    ),
                    backgroundColor: AppColors.successLight,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerLight,
              foregroundColor: AppColors.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(deleteButtonTextKey),
          ),
        ],
      );
    },
  );
}
