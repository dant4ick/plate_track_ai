import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/shared/widgets/status_snack_bar.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

class UserSetupScreen extends StatefulWidget {
  final bool isEditing;
  final Future<void> Function()? onComplete;

  const UserSetupScreen({super.key, this.isEditing = false, this.onComplete});

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
  final _goalWeightController = TextEditingController();

  // Form state
  Gender _selectedGender = Gender.male;
  ActivityLevel _selectedActivityLevel = ActivityLevel.moderatelyActive;
  NutritionGoal _selectedNutritionGoal = NutritionGoal.maintenance;
  CalorieReduction _selectedCalorieReduction = CalorieReduction.moderate;
  String _selectedLanguage = 'en'; // Default language

  bool _isLoading = false;
  double _calculatedBMR = 0;
  double _calculatedTDEE = 0;
  double _calculatedTarget = 0;
  bool _weightLossUnavailable = false;

  @override
  void initState() {
    super.initState();
    _initializeService();

    // Add listeners to recalculate BMR when inputs change
    _ageController.addListener(_calculateBMR);
    _weightController.addListener(_calculateBMR);
    _heightController.addListener(_calculateBMR);
    // The goal field's helper text quotes the healthy minimum for the height
    // typed so far, so it has to follow the height field keystroke by keystroke.
    _heightController.addListener(() => setState(() {}));
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
    if (!mounted) return;
    if (widget.isEditing && _userProfileService.hasUserProfile) {
      final profile = _userProfileService.currentProfile!;
      setState(() {
        _ageController.text = profile.age.toString();
        _weightController.text = profile.weight.toString();
        _heightController.text = profile.height.toString();
        _goalWeightController.text = _formatKg(profile.goalWeight);
        _selectedGender = profile.gender;
        _selectedActivityLevel = profile.activityLevel;
        _selectedNutritionGoal = profile.nutritionGoal;
        _selectedCalorieReduction = profile.calorieReduction;
      });
      _calculateBMR();
    }
  }

  /// "67" for a whole number, "67.5" otherwise, "" for none.
  static String _formatKg(double? kg) {
    if (kg == null) return '';
    return kg % 1 == 0 ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
  }

  /// Accepts `70.5` and `70,5`: the numeric keyboard offers a comma as the
  /// decimal separator in the Russian locale the app ships.
  static double? _parseKg(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  /// The floor for the goal field, or null until a valid height is entered.
  double? get _minimumGoalWeight {
    final height = double.tryParse(_heightController.text);
    if (height == null || height < 100 || height > 250) return null;
    return UserProfile.minimumHealthyWeight(height);
  }

  void _calculateBMR() {
    final age = int.tryParse(_ageController.text);
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);

    final valid =
        age != null &&
        age >= 10 &&
        age <= 120 &&
        weight != null &&
        weight.isFinite &&
        weight >= 20 &&
        weight <= 300 &&
        height != null &&
        height.isFinite &&
        height >= 100 &&
        height <= 250;
    final preview = valid
        ? UserProfile(
            id: 'preview',
            age: age,
            weight: weight,
            height: height,
            gender: _selectedGender,
            activityLevel: _selectedActivityLevel,
            nutritionGoal: _selectedNutritionGoal,
            calorieReduction: _selectedCalorieReduction,
            createdAt: DateTime.now(),
          )
        : null;
    setState(() {
      _weightLossUnavailable =
          preview != null &&
          _selectedNutritionGoal == NutritionGoal.weightLoss &&
          !preview.canUseWeightLossTargets;
      _calculatedBMR = preview?.calculateBMR() ?? 0;
      _calculatedTDEE = preview?.calculateTDEE() ?? 0;
      _calculatedTarget = _weightLossUnavailable
          ? 0
          : preview?.calculateCalorieTarget() ?? 0;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_weightLossUnavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        StatusSnackBar.error(context, message: 'weight_loss_unavailable'.tr()),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final goalWeight = _parseKg(_goalWeightController.text);

      if (widget.isEditing) {
        await _userProfileService.updateProfile(
          age: age,
          weight: weight,
          height: height,
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
          nutritionGoal: _selectedNutritionGoal,
          calorieReduction: _selectedCalorieReduction,
          goalWeight: goalWeight,
        );
      } else {
        await _userProfileService.createProfile(
          age: age,
          weight: weight,
          height: height,
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
          nutritionGoal: _selectedNutritionGoal,
          calorieReduction: _selectedCalorieReduction,
          goalWeight: goalWeight,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          StatusSnackBar.success(
            context,
            message: widget.isEditing
                ? 'profile_updated_successfully'.tr()
                : 'profile_created_successfully'.tr(),
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
          StatusSnackBar.error(
            context,
            message: 'error_saving_profile'.tr(
              namedArgs: {'error': e.toString()},
            ),
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
        StatusSnackBar.success(context, message: 'language_changed'.tr()),
      );
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalWeightController.dispose();
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
        padding: AppDimens.pagePadding(context),
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
              _buildNutritionGoalSection(),

              const SizedBox(height: 24),

              _buildBMRResultsSection(),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: widget.isEditing
                      ? 'update_profile'.tr()
                      : 'complete'.tr(),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildLanguageTile(
    String languageCode,
    String languageName,
    String flag,
  ) {
    final isSelected = _selectedLanguage == languageCode;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.onSurface
              : AppPalette.of(context).border,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : null,
      ),
      child: ListTile(
        leading: Text(flag, style: const TextStyle(fontSize: 24)),
        title: Text(
          languageName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.onSurface,
              )
            : null,
        onTap: () => _changeLanguage(languageCode),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurface,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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

            _buildGoalWeightField(),

            const SizedBox(height: 16),

            // Gender selection
            Text(
              'gender'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
              child: Column(
                children: [
                  RadioListTile<Gender>(
                    title: Text(Gender.male.displayName),
                    value: Gender.male,
                  ),
                  RadioListTile<Gender>(
                    title: Text(Gender.female.displayName),
                    value: Gender.female,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Target weight. Required, and floored at the healthy-BMI weight for the
  /// entered height — the app will not help set a goal of being underweight.
  Widget _buildGoalWeightField() {
    final minimum = _minimumGoalWeight;

    return TextFormField(
      controller: _goalWeightController,
      decoration: InputDecoration(
        labelText: 'goal_weight'.tr(),
        suffixText: 'kg'.tr(),
        helperText: minimum == null
            ? 'enter_height_for_goal_hint'.tr()
            : 'min_healthy_weight_hint'.tr(
                namedArgs: {'min': minimum.toStringAsFixed(1)},
              ),
        helperMaxLines: 2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.flag_outlined),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: (value) {
        final raw = (value ?? '').trim();
        if (raw.isEmpty) return 'please_enter_your_goal_weight'.tr();
        final goal = _parseKg(raw);
        if (goal == null || goal < 20 || goal > 300) {
          return 'please_enter_valid_goal_weight'.tr();
        }
        final floor = _minimumGoalWeight;
        if (floor != null && goal < floor) {
          return 'goal_weight_below_minimum'.tr(
            namedArgs: {'min': floor.toStringAsFixed(1)},
          );
        }
        return null;
      },
    );
  }

  Widget _buildActivityLevelSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'activity_level'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                children: ActivityLevel.values
                    .map((level) => _buildActivityLevelTile(level))
                    .toList(),
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
              ? Theme.of(context).colorScheme.onSurface
              : AppPalette.of(context).border,
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
            fontWeight: _selectedActivityLevel == level
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${level.description} (${level.multiplier}x)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        value: level,
      ),
    );
  }

  Widget _buildNutritionGoalSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'nutrition_goal'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            RadioGroup<NutritionGoal>(
              groupValue: _selectedNutritionGoal,
              onChanged: (value) {
                _selectedNutritionGoal = value!;
                _calculateBMR();
              },
              child: Column(
                children: NutritionGoal.values
                    .map(
                      (goal) => RadioListTile<NutritionGoal>(
                        title: Text(goal.displayName),
                        value: goal,
                      ),
                    )
                    .toList(),
              ),
            ),
            if (_selectedNutritionGoal == NutritionGoal.weightLoss) ...[
              const SizedBox(height: 16),
              Text(
                'weight_loss_caution'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text(
                'calorie_reduction'.tr(),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioGroup<CalorieReduction>(
                groupValue: _selectedCalorieReduction,
                onChanged: (value) {
                  _selectedCalorieReduction = value!;
                  _calculateBMR();
                },
                child: Column(
                  children: CalorieReduction.values
                      .map(
                        (level) => RadioListTile<CalorieReduction>(
                          title: Text(
                            '${level.displayName} (${(level.fraction * 100).round()}%)',
                          ),
                          value: level,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBMRResultsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.onSurface,
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
              if (_weightLossUnavailable) ...[
                Text(
                  'weight_loss_unavailable'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 12),
              ],
              _buildResultCard(
                'bmr_label'.tr(),
                '${_calculatedBMR.toInt()} ${'kcal'.tr()}/${'day'.tr()}',
                'bmr_description'.tr(),
                Icons.local_fire_department,
              ),

              const SizedBox(height: 12),

              _buildResultCard(
                'tdee_label'.tr(),
                '${_calculatedTDEE.toInt()} ${'kcal'.tr()}/${'day'.tr()}',
                'tdee_description'.tr(),
                Icons.restaurant,
              ),
              if (_selectedNutritionGoal == NutritionGoal.weightLoss &&
                  !_weightLossUnavailable) ...[
                const SizedBox(height: 12),
                _buildResultCard(
                  'calorie_target'.tr(),
                  '${_calculatedTarget.toInt()} ${'kcal'.tr()}/${'day'.tr()}',
                  'calorie_target_description'.tr(),
                  Icons.flag_outlined,
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppPalette.of(context).placeholder,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'enter_info_to_see_bmr'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildResultCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.of(context).border),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
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
