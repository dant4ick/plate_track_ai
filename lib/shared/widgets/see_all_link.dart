import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/themes/app_dimens.dart';

/// The trailing link on a section header that has a dedicated screen behind it.
class SeeAllLink extends StatelessWidget {
  const SeeAllLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          children: [
            Text(
              'see_all'.tr(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 18, color: primary),
          ],
        ),
      ),
    );
  }
}
