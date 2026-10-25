import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/features/meals/meal_detail_screen.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/delete_food.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

/// A headed list of meals. Every card opens [MealDetailScreen], where the meal
/// can be deleted; [showDeleteButton] additionally keeps the inline ✕.
Widget buildFoodItemSection({
  required BuildContext context,
  required List<FoodItem> items,
  required VoidCallback refreshCallback,
  Widget? trailing,
  bool showTimestamp = true,
  bool showDeleteButton = false,
}) {
  final palette = AppPalette.of(context);

  if (items.isEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('recent_items'.tr()),
        SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: palette.placeholder,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 34,
                  color: palette.placeholderIcon,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'no_food_items_yet'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'start_tracking_message'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader('recent_items'.tr(), trailing: trailing),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return FoodItemCard(
            item: item,
            showTimestamp: showTimestamp,
            onTap: () => _openDetail(context, item, refreshCallback),
            onDelete: () => _handleDelete(context, item, refreshCallback),
            showDeleteButton: showDeleteButton,
          );
        },
      ),
    ],
  );
}

Future<void> _openDetail(
  BuildContext context,
  FoodItem item,
  VoidCallback refreshCallback,
) async {
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => MealDetailScreen(item: item)));
  refreshCallback();
}

Future<void> _handleDelete(
  BuildContext context,
  FoodItem item,
  VoidCallback refreshCallback,
) async {
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
