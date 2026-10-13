import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/theme_controller.dart';

/// Debug-only app-bar control for flipping between the three design themes.
///
/// Labels are intentionally not localized — this never reaches a user, so it
/// stays out of the translation files. [StandardAppBar] only mounts it under
/// `kDebugMode`.
class ThemeSwitcherButton extends StatelessWidget {
  const ThemeSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemePreference>(
      valueListenable: themePreference,
      builder: (context, current, _) {
        return PopupMenuButton<ThemePreference>(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Theme (debug)',
          initialValue: current,
          onSelected: (value) => themePreference.value = value,
          itemBuilder: (context) => [
            _item(current, ThemePreference.system, 'System', null),
            _item(current, ThemePreference.light, 'Light',
                AppColors.secondShade),
            _item(current, ThemePreference.dark, 'Dark', AppColors.prime),
            _item(current, ThemePreference.pickMe, 'Pick me', AppColors.pick),
          ],
        );
      },
    );
  }

  /// One menu row: a swatch of the theme's primary, its name, and a check on
  /// whichever is active. [swatch] is null for "System", which has no colour
  /// of its own.
  PopupMenuItem<ThemePreference> _item(
    ThemePreference current,
    ThemePreference value,
    String label,
    Color? swatch,
  ) {
    return PopupMenuItem<ThemePreference>(
      value: value,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: swatch == null
                ? const Icon(Icons.brightness_auto, size: 16)
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          if (value == current) const Icon(Icons.check, size: 16),
        ],
      ),
    );
  }
}
