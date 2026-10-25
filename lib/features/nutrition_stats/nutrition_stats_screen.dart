import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/shared/widgets/weekly_averages.dart';
import 'package:plate_track_ai/shared/widgets/weekly_calories_chart.dart';
import 'package:plate_track_ai/shared/widgets/food_items.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';

class NutritionStatsScreen extends StatefulWidget {
  const NutritionStatsScreen({super.key});

  @override
  State<NutritionStatsScreen> createState() => _NutritionStatsScreenState();
}

class _NutritionStatsScreenState extends State<NutritionStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FoodStorageService _storageService = FoodStorageService();
  final UserProfileService _userProfileService = UserProfileService();

  // Data states
  List<FoodItem> _todaysFoodItems = [];
  List<List<FoodItem>> _weeklyFoodItems = [];

  /// Derived from [_weeklyFoodItems]; the weekly chart and averages read this
  /// rather than recomputing the same sums twice.
  WeekSummary _week = WeekSummary.empty();
  bool _isLoading = true;

  // Nutrition summary
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;

  // Target values (will be loaded from user profile or use defaults)
  double _targetCalories = 2000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize services and load data
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _userProfileService.initialize();
    _loadUserTargets();
    _loadFoodData();
  }

  void _loadUserTargets() {
    final targets = _userProfileService.getNutritionTargets();
    if (targets != null) {
      _targetCalories = targets['calories']!;
    }
  }

  Future<void> _loadFoodData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load today's food items
      final today = DateTime.now();
      _todaysFoodItems = await _storageService.getFoodItemsByDate(today);

      // Calculate today's nutrition totals
      _calculateTodayTotals();

      // Load weekly data - past 7 days including today
      _weeklyFoodItems = [];
      for (int i = 6; i >= 0; i--) {
        final date = DateTime(today.year, today.month, today.day - i);
        final items = await _storageService.getFoodItemsByDate(date);
        _weeklyFoodItems.add(items);
      }
      _week = WeekSummary.fromDays(_weeklyFoodItems);
    } catch (e) {
      // Use sample data as fallback
      _todaysFoodItems = [];
      _weeklyFoodItems = List.generate(7, (_) => []);
      _week = WeekSummary.empty();
      _totalCalories = 0;
      _totalProtein = 0;
      _totalCarbs = 0;
      _totalFat = 0;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateTodayTotals() {
    _totalCalories = 0;
    _totalProtein = 0;
    _totalCarbs = 0;
    _totalFat = 0;

    for (final item in _todaysFoodItems) {
      // Calculate total nutrition based on per 100g values and actual mass
      final double mass = item.nutritionFacts.mass ?? 100.0;
      _totalCalories += (item.calories * mass) / 100.0;
      _totalProtein += (item.nutritionFacts.protein * mass) / 100.0;
      _totalCarbs += (item.nutritionFacts.carbs * mass) / 100.0;
      _totalFat += (item.nutritionFacts.fat * mass) / 100.0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: StandardAppBar(
          onRefresh: _loadFoodData,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'daily_stats'.tr()),
              Tab(text: 'weekly_stats'.tr()),
            ],
            indicatorColor: Theme.of(context).colorScheme.onSurface,
            labelColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: StandardAppBar(
        onRefresh: _loadFoodData,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'daily_stats'.tr()),
            Tab(text: 'weekly_stats'.tr()),
          ],
          indicatorColor: Theme.of(context).colorScheme.onSurface,
          labelColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
        children: [_buildDailyStatsTab(), _buildWeeklyStatsTab()],
      ),
    );
  }

  Widget _buildDailyStatsTab() {
    return RefreshIndicator(
      onRefresh: _loadFoodData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppDimens.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderSection(),

            const SizedBox(height: 24),

            // Calorie summary card
            _buildCalorieCard(),

            const SizedBox(height: 24),

            // Nutrient breakdown chart
            Text(
              'nutrient_breakdown'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildNutrientPieChart(),

            const SizedBox(height: 24),

            // Food items list
            Text(
              'todays_food'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFoodItemsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStatsTab() {
    return RefreshIndicator(
      onRefresh: _loadFoodData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppDimens.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly calorie line chart
            Text(
              'weekly_calories'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            WeeklyCaloriesChart(summary: _week),

            const SizedBox(height: 24),

            // Weekly nutrient averages
            Text(
              'weekly_averages'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            WeeklyAverages(summary: _week),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCard() {
    final double consumedCalories = _totalCalories;
    final double targetCalories = _targetCalories;
    final double progressPercentage = consumedCalories / targetCalories;

    return Card(
      elevation: 2,
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
                    color: AppPalette.of(
                      context,
                    ).fillOf(AppPalette.of(context).calories),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: AppPalette.of(context).calories,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'calories_consumed'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${consumedCalories.toInt().toString()} / ${targetCalories.toInt().toString()} ${'kcal'.tr()}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppPalette.of(context).caloriesInk,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: AppPalette.of(context).track,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppPalette.of(context).calories,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progressPercentage * 100).toInt()}% ${'of_goal'.tr()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPalette.of(context).textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: progressPercentage >= 1.0
                        ? AppPalette.of(
                            context,
                          ).fillOf(AppPalette.of(context).success)
                        : AppPalette.of(
                            context,
                          ).fillOf(AppPalette.of(context).warning),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    progressPercentage >= 1.0
                        ? 'goal_reached'.tr()
                        : 'keep_going'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: progressPercentage >= 1.0
                          ? Theme.of(context).colorScheme.onSurface
                          : AppPalette.of(context).warningText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientPieChart() {
    // Real nutrient data
    final nutrientData = [
      PieChartSectionData(
        color: AppColors.protein,
        value: _totalProtein,
        title: '${_totalProtein.toInt()}${'g'.tr()}',
        radius: 50,
        titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppPalette.of(context).foregroundOn(AppColors.protein),
        ),
      ),
      PieChartSectionData(
        color: AppColors.carbs,
        value: _totalCarbs,
        title: '${_totalCarbs.toInt()}${'g'.tr()}',
        radius: 50,
        titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppPalette.of(context).foregroundOn(AppColors.carbs),
        ),
      ),
      PieChartSectionData(
        color: AppColors.fat,
        value: _totalFat,
        title: '${_totalFat.toInt()}${'g'.tr()}',
        radius: 50,
        titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppPalette.of(context).foregroundOn(AppColors.fat),
        ),
      ),
    ];

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppPalette.of(context).shadow,
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _totalProtein + _totalCarbs + _totalFat > 0
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: nutrientData,
                    ),
                  )
                : Center(
                    child: Text(
                      'no_nutrition_data_today'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPalette.of(context).textSecondary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(
                AppColors.protein,
                'protein'.tr(),
                '${_totalProtein.toInt()}${'g'.tr()}',
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                AppColors.carbs,
                'carbs'.tr(),
                '${_totalCarbs.toInt()}${'g'.tr()}',
              ),
              const SizedBox(height: 12),
              _buildLegendItem(
                AppColors.fat,
                'fat'.tr(),
                '${_totalFat.toInt()}${'g'.tr()}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodItemsList() {
    return buildFoodItemSection(
      context: context,
      items: _todaysFoodItems,
      refreshCallback: _loadFoodData,
    );
  }

  Widget _buildHeaderSection() {
    String message;
    IconData icon;

    if (_totalCalories == 0) {
      message = 'start_tracking_message'.tr();
      icon = Icons.emoji_food_beverage;
    } else if (_totalCalories < _targetCalories * 0.5) {
      message = 'good_start_today'.tr();
      icon = Icons.emoji_events;
    } else if (_totalCalories >= _targetCalories) {
      message = 'great_job_reaching_goal'.tr();
      icon = Icons.check_circle;
    } else {
      message = 'keep_up_the_great_work'.tr();
      icon = Icons.trending_up;
    }

    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
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
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'nutrition_overview'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
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
}
