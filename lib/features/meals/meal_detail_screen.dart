import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/bottom_action_bar.dart';
import 'package:plate_track_ai/shared/widgets/delete_food.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';

/// One logged meal in full: photo, name, when it was logged, the portion, and
/// the nutrition for that portion. Deleting lives here, behind a confirmation.
///
/// Pops with `true` after a deletion so the caller can refresh.
class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({super.key, required this.item});

  final FoodItem item;

  Future<void> _delete(BuildContext context) async {
    var deleted = false;

    await showDeleteConfirmationDialog(
      context: context,
      item: item,
      onDeleteConfirmed: () async {
        await FoodStorageService().deleteFoodItem(item.id);
        deleted = true;
      },
      confirmationTextKey: 'delete_food_item_confirm'.tr(),
      undoWarningTextKey: 'this_action_cannot_be_undone'.tr(),
      successMessageKey: 'food_item_deleted_successfully'.tr(),
      deleteButtonTextKey: 'delete'.tr(),
    );

    if (deleted && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    // Nutrition facts are stored per 100 g; everything shown is for the portion.
    final mass = item.nutritionFacts.mass ?? 100.0;
    double per(double per100) => (per100 * mass) / 100.0;

    final logged = DateFormat(
      'EEEE, d MMM yyyy · HH:mm',
      context.locale.toString(),
    ).format(item.timestamp);

    return Scaffold(
      appBar: StandardAppBar(titleText: 'meal_details'.tr(), showLogo: false),
      body: SingleChildScrollView(
        padding: AppDimens.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Photo(imagePath: item.imagePath),
            const SizedBox(height: AppDimens.sectionGap),
            Text(
              item.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${'logged_at'.tr()}: $logged',
              style: theme.textTheme.bodySmall?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: AppDimens.sectionGap),
            SectionHeader('nutrition_facts'.tr()),
            SoftCard(
              child: Column(
                children: [
                  _FactRow(
                    icon: Icons.scale_outlined,
                    label: 'portion_size'.tr(),
                    value: '${mass.round()} ${'g'.tr()}',
                    color: palette.textSecondary,
                  ),
                  const SizedBox(height: 14),
                  _FactRow(
                    icon: Icons.local_fire_department,
                    label: 'calories'.tr(),
                    value: '${per(item.calories).round()} ${'kcal'.tr()}',
                    color: palette.calories,
                  ),
                  const SizedBox(height: 14),
                  _FactRow(
                    icon: Icons.fitness_center,
                    label: 'protein'.tr(),
                    value:
                        '${per(item.nutritionFacts.protein).round()} ${'g'.tr()}',
                    color: palette.proteinInk,
                  ),
                  const SizedBox(height: 14),
                  _FactRow(
                    icon: Icons.grain,
                    label: 'carbs'.tr(),
                    value:
                        '${per(item.nutritionFacts.carbs).round()} ${'g'.tr()}',
                    color: palette.carbsInk,
                  ),
                  const SizedBox(height: 14),
                  _FactRow(
                    icon: Icons.opacity,
                    label: 'fat'.tr(),
                    value:
                        '${per(item.nutritionFacts.fat).round()} ${'g'.tr()}',
                    color: palette.fatInk,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          ElevatedButton.icon(
            onPressed: () => _delete(context),
            style: AppTheme.filledButtonStyle(
              backgroundColor: palette.danger,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusControl),
              ),
            ),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final path = imagePath;

    Widget placeholder() => Center(
      child: Icon(Icons.restaurant, size: 48, color: palette.placeholderIcon),
    );

    return ClipRRect(
      borderRadius: AppDimens.cardBorderRadius,
      child: Container(
        height: 220,
        width: double.infinity,
        color: palette.placeholder,
        child: path == null
            ? placeholder()
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                // The file can be gone while its path lives on in the record.
                errorBuilder: (_, _, _) => placeholder(),
              ),
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: palette.fillOf(color),
            borderRadius: BorderRadius.circular(AppDimens.radiusControl),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
