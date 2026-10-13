import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/features/recommendations/nutrition_advice.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';
import 'package:plate_track_ai/shared/widgets/tip_card.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final FoodStorageService _storageService = FoodStorageService();
  final UserProfileService _userProfileService = UserProfileService();
  bool _isLoading = false;

  // Nutrition summary for the past week
  double _avgCalories = 0;
  double _avgProtein = 0;
  double _avgCarbs = 0;
  double _avgFat = 0;

  // Target values (will be loaded from user profile or use defaults)
  double _targetCalories = 2000;
  double _targetProtein = 80;
  double _targetCarbs = 250;
  double _targetFat = 70;

  // Personalised advice, produced by the shared NutritionAdvice rules so this
  // screen and the dashboard can never disagree about what to suggest.
  List<NutritionTip> _recommendations = [];

  @override
  void initState() {
    super.initState();
    // Initialize services and load data
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize the storage service
    _storageService.initialize();

    // Initialize user profile service and load targets
    await _userProfileService.initialize();
    _loadUserTargets();

    // Load food data
    _loadData();
  }

  void _loadUserTargets() {
    final targets = _userProfileService.getNutritionTargets();
    if (targets != null) {
      setState(() {
        _targetCalories = targets['calories']!;
        _targetProtein = targets['protein']!;
        _targetCarbs = targets['carbs']!;
        _targetFat = targets['fat']!;
      });
    }
  }

  // Don't need to load data in the build method, it will be triggered by the ValueListenable
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      int daysWithData = 0;
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      // Analyze the past 7 days of food data
      for (int i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        final items = await _storageService.getFoodItemsByDate(date);

        if (items.isNotEmpty) {
          daysWithData++;

          for (final item in items) {
            // Calculate actual nutrition values based on mass
            final double mass = item.nutritionFacts.mass ?? 100.0;
            totalCalories += (item.calories * mass) / 100.0;
            totalProtein += (item.nutritionFacts.protein * mass) / 100.0;
            totalCarbs += (item.nutritionFacts.carbs * mass) / 100.0;
            totalFat += (item.nutritionFacts.fat * mass) / 100.0;
          }
        }
      }

      // Calculate averages if we have data
      if (daysWithData > 0) {
        _avgCalories = totalCalories / daysWithData;
        _avgProtein = totalProtein / daysWithData;
        _avgCarbs = totalCarbs / daysWithData;
        _avgFat = totalFat / daysWithData;
      } else {
        // Default values if no data
        _avgCalories = 0;
        _avgProtein = 0;
        _avgCarbs = 0;
        _avgFat = 0;
      }

      // Generate personalized recommendations
      _generateRecommendations();
    } catch (e) {
      // Use default recommendations if there's an error
      _useDefaultRecommendations();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _generateRecommendations() {
    _recommendations = NutritionAdvice.forWeek(
      averages: NutritionAverages(
        calories: _avgCalories,
        protein: _avgProtein,
        carbs: _avgCarbs,
        fat: _avgFat,
      ),
      targets: NutritionTargets(
        calories: _targetCalories,
        protein: _targetProtein,
        carbs: _targetCarbs,
        fat: _targetFat,
      ),
    );
  }

  void _useDefaultRecommendations() {
    _recommendations = NutritionAdvice.general();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _storageService.foodBoxListenable,
      builder: (context, box, child) {
        // Don't call _loadData() here - that was causing the error
        // Instead, call it inside didUpdateWidget or use a useEffect pattern

        return Scaffold(
          appBar: StandardAppBar(onRefresh: _loadData),
          body:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppDimens.pagePadding(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header section
                          _buildHeaderSection(),

                          const SizedBox(height: 24),

                          // Daily nutrition insights card
                          _buildInsightsCard(),

                          const SizedBox(height: 24),

                          // Recommendations section
                          SectionHeader('improve_nutrition'.tr()),
                          _buildRecommendationsList(),
                        ],
                      ),
                    ),
                  ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    String message;
    IconData icon;
    Color iconColor;

    if (_avgCalories == 0) {
      message = 'start_tracking_meals'.tr();
      icon = Icons.restaurant_menu;
      iconColor = AppPalette.of(context).info;
    } else if (_avgCalories < _targetCalories * 0.8) {
      message = 'nutrition_data_good'.tr();
      icon = Icons.trending_up;
      iconColor = AppPalette.of(context).success;
    } else if (_avgCalories > _targetCalories * 1.2) {
      message = 'moderate_calorie_intake'.tr();
      icon = Icons.info;
      iconColor = AppPalette.of(context).warning;
    } else {
      message = 'nutrition_tracking_great'.tr();
      icon = Icons.check_circle;
      iconColor = AppPalette.of(context).success;
    }

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [iconColor.withValues(alpha: 0.1), iconColor.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'personalized_tips'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsCard() {
    // Calculate percentages of daily targets
    final proteinPercentage = (_avgProtein / _targetProtein).clamp(0.0, 1.5);
    final carbsPercentage = (_avgCarbs / _targetCarbs).clamp(0.0, 1.5);
    final fatPercentage = (_avgFat / _targetFat).clamp(0.0, 1.5);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'daily_nutrition_insights'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildNutrientProgressBar(
              context,
              'protein'.tr(),
              proteinPercentage,
              '${(proteinPercentage * 100).toInt()}% ${'of_goal'.tr()}',
              AppColors.protein,
            ),
            const SizedBox(height: 12),

            _buildNutrientProgressBar(
              context,
              'carbs'.tr(),
              carbsPercentage,
              '${(carbsPercentage * 100).toInt()}% ${'of_goal'.tr()}',
              AppColors.carbs,
            ),
            const SizedBox(height: 12),

            _buildNutrientProgressBar(
              context,
              'fat'.tr(),
              fatPercentage,
              '${(fatPercentage * 100).toInt()}% ${'of_goal'.tr()}',
              AppColors.fat,
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Personalized focus message
            _buildFocusMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusMessage() {
    String focusMessageKey = 'focus_on_balanced_diet'.tr();

    // Determine the nutrient that needs the most attention
    if (_avgProtein < _targetProtein * 0.7) {
      focusMessageKey = 'focus_increase_protein'.tr();
    } else if (_avgCalories < _targetCalories * 0.7) {
      focusMessageKey = 'focus_increase_calories'.tr();
    } else if (_avgCalories > _targetCalories * 1.3) {
      focusMessageKey = 'focus_reduce_calories'.tr();
    }

    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          TextSpan(
            text: '${'focus_today'.tr()}: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: focusMessageKey),
        ],
      ),
    );
  }

  Widget _buildNutrientProgressBar(
    BuildContext context,
    String title,
    double progress,
    String progressText,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(progressText, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppPalette.of(context).track,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => TipCard(tip: _recommendations[index]),
    );
  }
}
