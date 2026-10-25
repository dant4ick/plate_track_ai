import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/shared/widgets/macro_chip.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: AppTheme.filledButtonStyle(
        backgroundColor: isSecondary ? scheme.secondary : scheme.primary,
        // Overriding the background without its matching foreground left the
        // button on the theme's default white, which on the lime secondary is
        // 1.13:1 — invisible. The scheme already pairs these correctly.
        foregroundColor: isSecondary ? scheme.onSecondary : scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: isSecondary ? scheme.onSecondary : scheme.onPrimary,
                strokeWidth: 2.0,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(text),
              ],
            ),
    );
  }
}

class NutritionCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const NutritionCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FrameGuideline extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color color;

  const FrameGuideline({
    super.key,
    required this.size,
    this.strokeWidth = 3.0,
    this.color = AppColors.cameraForeground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: strokeWidth),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback? onDelete;
  final bool showDeleteButton;
  final bool showMass;
  final bool showNutrientChips;
  final String? timeFormat;

  /// Whether the "when" line carries the timestamp. Off for lists that already
  /// say when — the dashboard's recent meals, a history grouped by day.
  final bool showTimestamp;

  /// Opens the meal's detail screen when set.
  final VoidCallback? onTap;

  const FoodItemCard({
    super.key,
    required this.item,
    this.onDelete,
    this.showDeleteButton = false,
    this.showMass = true,
    this.showNutrientChips = true,
    this.showTimestamp = true,
    this.timeFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // easy_localization's `context.locale` requires its widget above us; fall
    // back to the framework locale so the card also renders outside the app.
    final localeName =
        (EasyLocalization.of(context)?.locale ??
                Localizations.localeOf(context))
            .toString();
    final timeString = DateFormat(
      timeFormat ?? 'MMM d, h:mm a',
      localeName,
    ).format(item.timestamp);
    final double mass = item.nutritionFacts.mass ?? 100.0;
    final int actualCalories = ((item.calories * mass) / 100.0).toInt();
    final palette = AppPalette.of(context);
    final theme = Theme.of(context);

    // Nutrition facts are stored per 100 g, so every figure shown has to be
    // scaled to the portion actually eaten.
    double per(double per100) => (per100 * mass) / 100.0;

    // The secondary line: timestamp and portion, either of which may be off.
    final details = [
      if (showTimestamp) timeString,
      if (showMass) '${mass.toInt()}${'g'.tr()}',
    ].join(' · ');

    return SoftCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Thumbnail(imagePath: item.imagePath),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showDeleteButton && onDelete != null)
                      _DeleteButton(onDelete: onDelete!),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: palette.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (showNutrientChips) ...[
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      MacroChip(
                        macro: Macro.protein,
                        grams: per(item.nutritionFacts.protein),
                      ),
                      MacroChip(
                        macro: Macro.carbs,
                        grams: per(item.nutritionFacts.carbs),
                      ),
                      MacroChip(
                        macro: Macro.fat,
                        grams: per(item.nutritionFacts.fat),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Calories read as one phrase — figure then unit — rather than a
          // stacked pair, so the row has a single strong right-hand anchor.
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$actualCalories',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'kcal'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final radius = BorderRadius.circular(AppDimens.radiusThumb);
    final path = imagePath;

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: palette.placeholder,
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? Icon(Icons.restaurant, color: palette.placeholderIcon, size: 24)
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              // A stored path can outlive the file it points at, so a missing
              // image falls back to the placeholder instead of an error box.
              errorBuilder: (context, error, stack) => Icon(
                Icons.restaurant,
                color: palette.placeholderIcon,
                size: 24,
              ),
            ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: onDelete,
      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.close_rounded,
          size: 16,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
