import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';

import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/theme_controller.dart';

/// The user-facing theme choice, as a settings-screen section.
///
/// Writes straight to [themePreference]; persistence is the controller's job
/// (attached in `main()`), so this widget stays a pure view over the notifier
/// and needs no storage of its own to be tested.
class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'appearance'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<ThemePreference>(
            valueListenable: themePreference,
            builder: (context, current, _) {
              return RadioGroup<ThemePreference>(
                groupValue: current,
                onChanged: (value) {
                  if (value != null) themePreference.value = value;
                },
                child: Column(
                  children: [
                    _option(ThemePreference.system, 'theme_system'.tr(), null),
                    _option(
                      ThemePreference.light,
                      'theme_light'.tr(),
                      AppColors.secondShade,
                    ),
                    _option(
                      ThemePreference.dark,
                      'theme_dark'.tr(),
                      AppColors.prime,
                    ),
                    _option(
                      ThemePreference.pickMe,
                      // A brand name, same in every locale — not translated.
                      'Pick me',
                      AppColors.pick,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// One row: a swatch of the theme's primary, its name, and the radio.
  /// [swatch] is null for "System", which has no colour of its own.
  Widget _option(ThemePreference value, String label, Color? swatch) {
    return RadioListTile<ThemePreference>(
      value: value,
      title: Text(label),
      contentPadding: EdgeInsets.zero,
      secondary: SizedBox(
        width: 20,
        height: 20,
        child: swatch == null
            ? const Icon(Icons.brightness_auto, size: 20)
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }
}
