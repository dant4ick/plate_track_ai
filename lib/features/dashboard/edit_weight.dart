import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/features/dashboard/weight_goal_sheet.dart';

/// The whole "update weight" flow: open the sheet, persist what was entered,
/// confirm with a toast. Returns true if something was saved.
///
/// Shared by every screen with a weight card so the goal floor and the
/// clear-goal semantics cannot drift between them.
Future<bool> editWeightAndGoal(
  BuildContext context,
  UserProfileService service,
) async {
  final profile = service.currentProfile;
  if (profile == null) return false;

  final result = await WeightGoalSheet.show(
    context,
    weight: profile.weight,
    goalWeight: profile.goalWeight,
    minimumGoal: profile.minimumGoalWeight,
  );
  if (result == null) return false;

  await service.updateProfile(
    weight: result.weight,
    goalWeight: result.goalWeight,
    // An emptied goal field is a request to remove the goal, not to leave the
    // previous one in place.
    clearGoalWeight: result.goalWeight == null,
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('weight_updated_successfully'.tr())),
    );
  }
  return true;
}
