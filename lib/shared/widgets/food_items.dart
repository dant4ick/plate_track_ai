import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/delete_food.dart';

Widget buildFoodItemSection({
  required BuildContext context,
  required List<FoodItem> items,
  required VoidCallback refreshCallback,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  if (items.isEmpty) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.grey[700]!.withValues(alpha: 0.2)
                    : Colors.grey[400]!.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 48,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'no_food_items_yet'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'start_tracking_message'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'recent_items'.tr(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      const SizedBox(height: 12),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          return FoodItemCard(
            item: item,
            onDelete: () => _handleDelete(context, item, refreshCallback),
            showDeleteButton: true,
          );
        },
      ),
    ],
  );
}

Future<void> _handleDelete(BuildContext context, FoodItem item, VoidCallback refreshCallback) async {
  final FoodStorageService storageService = FoodStorageService();
  await showDeleteConfirmationDialog(
    context: context,
    item: item,
    onDeleteConfirmed: () async {
      await storageService.deleteFoodItem(item.id);
      refreshCallback();
    },
    confirmationTextKey: 'delete_food_item_confirm'.tr(),
    undoWarningTextKey: 'this_action_cannot_be_undone'.tr(),
    successMessageKey: 'food_item_deleted_successfully'.tr(),
    deleteButtonTextKey: 'delete'.tr(),
  );
}
