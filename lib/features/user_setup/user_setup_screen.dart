import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';

class UserSetupScreen extends StatefulWidget {
  final bool isEditing;
  final Future<void> Function()? onComplete;

  const UserSetupScreen({
    Key? key,
    this.isEditing = false,
    this.onComplete,
  }) : super(key: key);

  @override
  State<UserSetupScreen> createState() => _UserSetupScreenState();
}

class _UserSetupScreenState extends State<UserSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userProfileService = UserProfileService();
  
  // Form controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  // Form state
  Gender _selectedGender = Gender.male;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  
  bool _isLoading = false;
  double _calculatedBMR = 0;
  double _calculatedTDEE = 0;

  @override
  void initState() {
    super.initState();
    _initializeService();
    
    // Add listeners to recalculate BMR when inputs change
    _ageController.addListener(_calculateBMR);
    _weightController.addListener(_calculateBMR);
    _heightController.addListener(_calculateBMR);
  }

  Future<void> _initializeService() async {
    await _userProfileService.initialize();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    if (widget.isEditing && _userProfileService.hasUserProfile) {
      final profile = _userProfileService.currentProfile!;
      setState(() {
        _ageController.text = profile.age.toString();
        _weightController.text = profile.weight.toString();
        _heightController.text = profile.height.toString();
        _selectedGender = profile.gender;
        _selectedActivityLevel = profile.activityLevel;
      });
      _calculateBMR();
    }
  }

  void _calculateBMR() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    
    if (age != null && weight != null && height != null) {
      setState(() {
        // Calculate BMR using the provided formulas
        switch (_selectedGender) {
          case Gender.male:
            _calculatedBMR = 260 + (9.65 * weight) + (5.73 * height) - (5.08 * age);
            break;
          case Gender.female:
            _calculatedBMR = 43 + (7.38 * weight) + (6.07 * height) - (2.31 * age);
            break;
        }
        _calculatedTDEE = _calculatedBMR * _selectedActivityLevel.multiplier;
      });
    }
  }

  Future<void> _saveProfile() async {
    print('UserSetupScreen: _saveProfile called, isEditing: ${widget.isEditing}');
    if (!_formKey.currentState!.validate()) {
      print('UserSetupScreen: Form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);

      print('UserSetupScreen: Parsed values - age: $age, weight: $weight, height: $height, gender: $_selectedGender, activity: $_selectedActivityLevel');

      if (widget.isEditing) {
        print('UserSetupScreen: Updating existing profile');
        await _userProfileService.updateProfile(
          age: age,
          weight: weight,
          height: height,
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
        );
        print('UserSetupScreen: Profile updated successfully');
      } else {
        print('UserSetupScreen: Creating new profile');
        await _userProfileService.createProfile(
          age: age,
          weight: weight,
          height: height,
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
        );
        print('UserSetupScreen: Profile created successfully');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Profile updated successfully!' : 'Profile created successfully!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        print('UserSetupScreen: About to call onComplete callback, isEditing: ${widget.isEditing}');
        await widget.onComplete?.call();
        print('UserSetupScreen: onComplete callback completed');
        
        // Only pop navigation if we're editing an existing profile
        if (widget.isEditing) {
          print('UserSetupScreen: Popping navigation for editing mode');
          Navigator.of(context).pop(true);
        } else {
          print('UserSetupScreen: Not popping navigation - new profile creation');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? AppStrings.editProfile : AppStrings.userSetup),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              _buildHeaderCard(),
              
              const SizedBox(height: 24),
              
              // Personal Information section
              _buildPersonalInfoSection(),
              
              const SizedBox(height: 24),
              
              // Activity Level section
              _buildActivityLevelSection(),
              
              const SizedBox(height: 24),
              
              // BMR Calculation results
              _buildBMRResultsSection(),
              
              const SizedBox(height: 32),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: widget.isEditing ? 'Update Profile' : AppStrings.complete,
                  onPressed: _isLoading ? null : () => _saveProfile(),
                  isLoading: _isLoading,
                  icon: widget.isEditing ? Icons.edit : Icons.check,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
                          widget.isEditing ? AppStrings.editProfile : AppStrings.createProfile,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.isEditing 
                            ? 'Update your information to get accurate nutrition recommendations'
                            : 'Set up your profile to get personalized nutrition recommendations',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.personalInfo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Age field
            TextFormField(
              controller: _ageController,
              decoration: InputDecoration(
                labelText: AppStrings.age,
                suffixText: AppStrings.ageYears,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                final age = int.tryParse(value);
                if (age == null || age < 10 || age > 120) {
                  return 'Please enter a valid age (10-120)';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Weight field
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: AppStrings.weight,
                suffixText: AppStrings.weightKg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.monitor_weight),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight < 20 || weight > 300) {
                  return 'Please enter a valid weight (20-300 kg)';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Height field
            TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: AppStrings.height,
                suffixText: AppStrings.heightCm,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.height),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your height';
                }
                final height = double.tryParse(value);
                if (height == null || height < 100 || height > 250) {
                  return 'Please enter a valid height (100-250 cm)';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Gender selection
            Text(
              AppStrings.gender,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<Gender>(
                    title: Text(Gender.male.displayName),
                    value: Gender.male,
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                        _calculateBMR();
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<Gender>(
                    title: Text(Gender.female.displayName),
                    value: Gender.female,
                    groupValue: _selectedGender,
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                        _calculateBMR();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.activityLevel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...ActivityLevel.values.map((level) => _buildActivityLevelTile(level)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelTile(ActivityLevel level) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _selectedActivityLevel == level 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey[300]!,
          width: _selectedActivityLevel == level ? 2 : 1,
        ),
        color: _selectedActivityLevel == level 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      ),
      child: RadioListTile<ActivityLevel>(
        title: Text(
          level.displayName,
          style: TextStyle(
            fontWeight: _selectedActivityLevel == level ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${level.description} (${level.multiplier}x)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        value: level,
        groupValue: _selectedActivityLevel,
        onChanged: (value) {
          setState(() {
            _selectedActivityLevel = value!;
            _calculateBMR();
          });
        },
      ),
    );
  }

  Widget _buildBMRResultsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.bmrCalculation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_calculatedBMR > 0) ...[
              _buildResultCard(
                'BMR (Basal Metabolic Rate)',
                '${_calculatedBMR.toInt()} kcal/day',
                'Calories burned at rest',
                Icons.local_fire_department,
                Colors.orange[400]!,
              ),
              
              const SizedBox(height: 12),
              
              _buildResultCard(
                AppStrings.dailyCalorieNeeds,
                '${_calculatedTDEE.toInt()} kcal/day',
                'Total daily energy expenditure',
                Icons.restaurant,
                Colors.green[400]!,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter your information above to see your calculated BMR and daily calorie needs',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
