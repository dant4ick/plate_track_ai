import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/shared/widgets/camera_scan_overlay.dart';

/// Keep the hint above the actions as labels grow or the system inset changes.
class FoodCameraControls extends StatelessWidget {
  const FoodCameraControls({
    super.key,
    required this.isCapturing,
    required this.onGallery,
    required this.onTakePhoto,
  });

  final bool isCapturing;
  final VoidCallback? onGallery;
  final VoidCallback? onTakePhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CameraScanHint(
          text: isCapturing ? 'capturing'.tr() : 'frame_your_food'.tr(),
          bottomSpacing: 16,
          includeBottomInset: false,
        ),
        Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            36 + MediaQuery.paddingOf(context).bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cameraMask,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onGallery,
                  style: AppTheme.filledButtonStyle(
                    foregroundColor: colors.onSecondary,
                    backgroundColor: colors.secondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: Text(
                    'choose_photo'.tr(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTakePhoto,
                  style: AppTheme.filledButtonStyle(
                    foregroundColor: colors.onPrimary,
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: Text('take_photo'.tr(), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
