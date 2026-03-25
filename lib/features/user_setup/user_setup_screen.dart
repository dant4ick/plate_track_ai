import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';

class UserSetupScreen extends StatefulWidget {
  final bool isEditing;
  final Future<void> Function()? onComplete;

  const UserSetupScreen({
    super.key,
    this.isEditing = false,
    this.onComplete,
  });

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
  String _selectedLanguage = 'en'; // Default language
  
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set current language - this is safe to do here as context is fully available
    _selectedLanguage = context.locale.languageCode;
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);


      if (widget.isEditing) {
        await _userProfileService.updateProfile(
          age: age,
          weight: weight,
          height: height,
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
        );
      } else {
        await _userProfileService.createProfile(
          age: age,
          weight: weight,
          height: height,
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'profile_updated_successfully'.tr() : 'profile_created_successfully'.tr()),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        await widget.onComplete?.call();
        
        // Navigation logic based on context
        if (!mounted) return;
        
        if (widget.isEditing) {
          Navigator.of(context).pop(true);
        } else if (widget.onComplete != null) {
          // This handles the reset case - pop everything and let the app reinitialize
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // This is the normal app startup case - AppInitializer will handle the transition
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_saving_profile'.tr(namedArgs: {'error': e.toString()})),
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

  Future<void> _changeLanguage(String languageCode) async {
    Locale newLocale = Locale(languageCode);
    await context.setLocale(newLocale);
    setState(() {
      _selectedLanguage = languageCode;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('language_changed'.tr()),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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
      appBar: StandardAppBar(
        titleText: widget.isEditing ? 'edit_profile'.tr() : 'user_setup'.tr(),
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              // _buildHeaderCard(),
              
              // const SizedBox(height: 24),
              
              // Language Selection section
              _buildLanguageSection(),
              
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
                    text: widget.isEditing ? 'update_profile'.tr() : 'complete'.tr(),
                  onPressed: _isLoading ? null : () => _saveProfile(),
                  isLoading: _isLoading,
                  icon: Icons.check,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
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
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'language'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Language selection tiles
            _buildLanguageTile('en', 'english'.tr(), '🇺🇸'),
            const SizedBox(height: 8),
            _buildLanguageTile('ru', 'russian'.tr(), '🇷🇺'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String languageCode, String languageName, String flag) {
    final isSelected = _selectedLanguage == languageCode;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected 
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : null,
      ),
      child: ListTile(
        leading: Text(
          flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          languageName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected 
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
        onTap: () => _changeLanguage(languageCode),
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
                  'personal_info'.tr(),
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
                labelText: 'age'.tr(),
                suffixText: 'years'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.cake),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                    return 'please_enter_your_age'.tr();
                }
                final age = int.tryParse(value);
                if (age == null || age < 10 || age > 120) {
                    return 'please_enter_valid_age'.tr();
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Weight field
            TextFormField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'weight'.tr(),
                suffixText: 'kg'.tr(),
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
                    return 'please_enter_your_weight'.tr();
                }
                final weight = double.tryParse(value);
                if (weight == null || weight < 20 || weight > 300) {
                    return 'please_enter_valid_weight'.tr();
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Height field
            TextFormField(
              controller: _heightController,
              decoration: InputDecoration(
                labelText: 'height'.tr(),
                suffixText: 'cm'.tr(),
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
                    return 'please_enter_your_height'.tr();
                }
                final height = double.tryParse(value);
                if (height == null || height < 100 || height > 250) {
                    return 'please_enter_valid_height'.tr();
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Gender selection
            Text(
              'gender'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            RadioGroup<Gender>(
              groupValue: _selectedGender,
              onChanged: (value) {
                setState(() {
                  _selectedGender = value!;
                  _calculateBMR();
                });
              },
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<Gender>(
                      title: Text(Gender.male.displayName),
                      value: Gender.male,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<Gender>(
                      title: Text(Gender.female.displayName),
                      value: Gender.female,
                    ),
                  ),
                ],
              ),
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
                  'activity_level'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            RadioGroup<ActivityLevel>(
              groupValue: _selectedActivityLevel,
              onChanged: (value) {
                setState(() {
                  _selectedActivityLevel = value!;
                  _calculateBMR();
                });
              },
              child: Column(
                children: ActivityLevel.values.map((level) => _buildActivityLevelTile(level)).toList(),
              ),
            ),
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
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
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
                  'bmr_calculation'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_calculatedBMR > 0) ...[
              _buildResultCard(
                'bmr_label'.tr(),
                '${_calculatedBMR.toInt()} ${'kcal'.tr()}/${'day'.tr()}',
                'bmr_description'.tr(),
                Icons.local_fire_department,
                Colors.orange[400]!,
              ),
              
              const SizedBox(height: 12),
              
              _buildResultCard(
                'tdee_label'.tr(),
                '${_calculatedTDEE.toInt()} ${'kcal'.tr()}/${'day'.tr()}',
                'tdee_description'.tr(),
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
                        'enter_info_to_see_bmr'.tr(),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
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
