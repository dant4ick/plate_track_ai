import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/main.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({super.key});

  @override
  State<ProfileManagementScreen> createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  UserProfile? _currentProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userProfileService.initialize();
      final profile = _userProfileService.currentProfile;
      setState(() {
        _currentProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_loading_profile'.tr()}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (_currentProfile == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => UserSetupScreen(isEditing: true)),
    );

    if (result == true) {
      // Profile was updated, reload it
      _loadUserProfile();
    }
  }

  Future<void> _resetProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('reset_profile'.tr()),
        content: Text('reset_profile_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('reset'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userProfileService.deleteProfile();
        if (mounted) {
          // Navigate back to AppInitializer to properly handle the flow
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const AppInitializer(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'error_resetting_profile'.tr()}: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        onRefresh: _loadUserProfile,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentProfile == null
              ? _buildNoProfileView()
              : _buildProfileView(),
    );
  }

  Widget _buildNoProfileView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'no_profile_found'.tr(),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'create_profile_description'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const UserSetupScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: Text('create_profile'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final profile = _currentProfile!;
    final bmr = profile.calculateBMR();
    final tdee = profile.calculateTDEE();
    final targets = _userProfileService.getNutritionTargets();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _buildProfileHeader(),

          const SizedBox(height: 24),

          // Personal Information Section
          _buildPersonalInfoSection(profile),

          const SizedBox(height: 24),

          // Calculated Values Section
          _buildCalculatedValuesSection(bmr, tdee),

          const SizedBox(height: 24),

          // Nutrition Targets Section
          if (targets != null) _buildNutritionTargetsSection(targets),

          const SizedBox(height: 32),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: AppLogo(
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'your_profile'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentProfile!.age} ${'years'.tr()} • ${_currentProfile!.gender == Gender.male ? 'male'.tr() : 'female'.tr()}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _editProfile,
              icon: const Icon(Icons.settings),
              tooltip: 'edit_profile'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection(UserProfile profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'personal_info'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.cake,
              'age'.tr(),
              '${profile.age} ${'years'.tr()}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.monitor_weight,
              'weight'.tr(),
              '${profile.weight} ${'kg'.tr()}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.height, 'height'.tr(), '${profile.height} ${'cm'.tr()}'),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.directions_run,
              'activity_level'.tr(),
              _getActivityLevelDescription(profile.activityLevel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculatedValuesSection(double bmr, double tdee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'calculated_values'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.local_fire_department,
              'bmr_label'.tr(),
              '${bmr.toInt()} ${'kcal'.tr()}/${'day'.tr()}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.flash_on,
              'tdee_label'.tr(),
              '${tdee.toInt()} ${'kcal'.tr()}/${'day'.tr()}',
            ),
            const SizedBox(height: 8),
            Text(
              'tdee_description'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionTargetsSection(Map<String, double> targets) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'daily_nutrition_targets'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.local_fire_department,
              'calories'.tr(),
              '${targets['calories']!.toInt()} ${'kcal'.tr()}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.fitness_center,
              'protein'.tr(),
              '${targets['protein']!.toInt()} ${'g'.tr()}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.grain,
              'carbs'.tr(),
              '${targets['carbs']!.toInt()} ${'g'.tr()}',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.opacity,
              'fat'.tr(),
              '${targets['fat']!.toInt()} ${'g'.tr()}',
            ),
            const SizedBox(height: 8),
            Text(
              'macro_distribution_description'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            label: Text('edit_profile'.tr()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetProfile,
            icon: const Icon(Icons.refresh),
            label: Text('reset_profile'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  String _getActivityLevelDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'activity_sedentary'.tr();
      case ActivityLevel.lightlyActive:
        return 'activity_lightly_active'.tr();
      case ActivityLevel.moderatelyActive:
        return 'activity_moderately_active'.tr();
      case ActivityLevel.veryActive:
        return 'activity_very_active'.tr();
      case ActivityLevel.extremelyActive:
        return 'activity_extremely_active'.tr();
    }
  }
}
