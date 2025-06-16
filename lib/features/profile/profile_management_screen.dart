import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';

class ProfileManagementScreen extends StatefulWidget {
  const ProfileManagementScreen({Key? key}) : super(key: key);

  @override
  State<ProfileManagementScreen> createState() => _ProfileManagementScreenState();
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
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    if (_currentProfile == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UserSetupScreen(
          isEditing: true,
        ),
      ),
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
        title: const Text('Reset Profile'),
        content: const Text(
          'Are you sure you want to reset your profile? This will delete all your personal information and you\'ll need to set it up again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _userProfileService.deleteProfile();
        if (mounted) {
          // Navigate back to setup screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const UserSetupScreen(),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting profile: $e'),
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
      appBar: AppBar(
        title: const Text('Profile Settings'),
        elevation: 0,
      ),
      body: _isLoading
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
          Icon(
            Icons.person_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Profile Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a profile to get personalized nutrition recommendations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
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
            label: const Text('Create Profile'),
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
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                    'Your Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentProfile!.age} years old • ${_currentProfile!.gender == Gender.male ? 'Male' : 'Female'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Profile',
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
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.cake, 'Age', '${profile.age} years'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.monitor_weight, 'Weight', '${profile.weight} kg'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.height, 'Height', '${profile.height} cm'),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.directions_run,
              'Activity Level',
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
              'Calculated Values',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.local_fire_department,
              'Basal Metabolic Rate (BMR)',
              '${bmr.toInt()} kcal/day',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.flash_on,
              'Total Daily Energy Expenditure (TDEE)',
              '${tdee.toInt()} kcal/day',
            ),
            const SizedBox(height: 8),
            Text(
              'TDEE includes your activity level and represents your daily calorie needs.',
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
              'Daily Nutrition Targets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.local_fire_department,
              'Calories',
              '${targets['calories']!.toInt()} kcal',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.fitness_center,
              'Protein',
              '${targets['protein']!.toInt()} g',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.grain,
              'Carbohydrates',
              '${targets['carbohydrates']!.toInt()} g',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.opacity,
              'Fat',
              '${targets['fat']!.toInt()} g',
            ),
            const SizedBox(height: 8),
            Text(
              'Based on standard macro distribution: 20% protein, 50% carbs, 30% fat.',
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
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            label: const Text('Edit Profile'),
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
            label: const Text('Reset Profile'),
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
        return 'Sedentary (little/no exercise)';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active (light exercise)';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active (moderate exercise)';
      case ActivityLevel.veryActive:
        return 'Very Active (hard exercise)';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active (very hard exercise)';
    }
  }
}
