import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';

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
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary 
            ? Theme.of(context).colorScheme.secondary 
            : Theme.of(context).colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.onAccent,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color ?? Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color ?? Theme.of(context).colorScheme.primary,
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
        border: Border.all(
          color: color,
          width: strokeWidth,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
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

  const FoodItemCard({
    super.key,
    required this.item,
    this.onDelete,
    this.showDeleteButton = false,
    this.showMass = true,
    this.showNutrientChips = true,
    this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = timeFormat != null 
        ? DateFormat(timeFormat!, context.locale.toString()).format(item.timestamp)
        : DateFormat('MMM d, h:mm a', context.locale.toString()).format(item.timestamp);
    final double mass = item.nutritionFacts.mass ?? 100.0;
    final int actualCalories = ((item.calories * mass) / 100.0).toInt();
    final palette = AppPalette.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Leading image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: palette.placeholder,
              ),
              child: item.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(item.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.restaurant,
                      color: palette.placeholderIcon,
                    ),
            ),
            const SizedBox(width: 12),
            
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with delete button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (showDeleteButton && onDelete != null)
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: palette.dangerSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.dangerBorder,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: palette.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Time and mass
                  Text(
                    showMass ? '$timeString · ${mass.toInt()}${'g'.tr()}' : timeString,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Bottom row with nutrients and calories
                    Row(
                    children: [
                      if (showNutrientChips) ...[
                      Expanded(
                        child: Wrap(
                        spacing: 4,
                        children: [
                          _buildNutrientChip(
                          '${'protein_short'.tr()}: ${((item.nutritionFacts.protein * mass) / 100).toInt()}${'g'.tr()}',
                          AppColors.protein,
                          palette.proteinFill,
                          ),
                          _buildNutrientChip(
                          '${'carbs_short'.tr()}: ${((item.nutritionFacts.carbs * mass) / 100).toInt()}${'g'.tr()}',
                          AppColors.carbs,
                          palette.carbsFill,
                          ),
                          _buildNutrientChip(
                          '${'fat_short'.tr()}: ${((item.nutritionFacts.fat * mass) / 100).toInt()}${'g'.tr()}',
                          AppColors.fat,
                          palette.fatFill,
                          ),
                        ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ],
                      
                      // Calories
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$actualCalories',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: palette.calories,
                                ),
                          ),
                          Text(
                            'kcal'.tr(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text, Color color, Color fill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}