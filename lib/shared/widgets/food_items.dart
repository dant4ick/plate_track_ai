import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/features/meals/meal_detail_screen.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/recent_meal_group.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/delete_food.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

/// Recent meals grouped by local hour today and by calendar date otherwise.
/// Every card opens [MealDetailScreen], where the meal can be deleted;
/// [showDeleteButton] additionally keeps the inline ✕. History has its own
/// day sections and only uses this widget for its empty state.
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

  final now = DateTime.now();
  final groups = groupRecentMeals(items, now: now);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader('recent_items'.tr(), trailing: trailing),
      for (final group in groups) ...[
        _RecentMealDivider(group: group, now: now),
        for (final item in group.items) ...[
          FoodItemCard(
            item: item,
            showTimestamp: showTimestamp,
            onTap: () => _openDetail(context, item, refreshCallback),
            onDelete: () => _handleDelete(context, item, refreshCallback),
            showDeleteButton: showDeleteButton,
          ),
          const SizedBox(height: 10),
        ],
      ],
    ],
  );
}

class _RecentMealDivider extends StatelessWidget {
  const _RecentMealDivider({required this.group, required this.now});

  final RecentMealGroup group;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (group.hour case final hour?) {
      final hh = hour.toString().padLeft(2, '0');
      label = 'recent_meals_today_hour'.tr(
        namedArgs: {'start': '$hh:00', 'end': '$hh:59'},
      );
    } else if (group.date == DateTime(now.year, now.month, now.day - 1)) {
      label = 'recent_meals_yesterday'.tr();
    } else {
      final locale = context.locale.toString();
      label =
          (group.date.year == now.year
                  ? DateFormat.MMMMd(locale)
                  : DateFormat.yMMMMd(locale))
              .format(group.date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppPalette.of(context).textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }
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
