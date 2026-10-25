import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:plate_track_ai/core/services/local_data_observer.dart';
import 'package:plate_track_ai/core/services/food_recognition_service.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/features/meals/meal_history_screen.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_stats_screen.dart';
import 'package:plate_track_ai/features/profile/profile_management_screen.dart';
import 'package:plate_track_ai/features/weight/weight_history_screen.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:plate_track_ai/shared/models/week_summary.dart';
import 'package:plate_track_ai/shared/widgets/calorie_gauge.dart';
import 'package:plate_track_ai/shared/widgets/food_items.dart';
import 'package:plate_track_ai/shared/widgets/macro_bars.dart';
import 'package:plate_track_ai/shared/widgets/see_all_link.dart';
import 'package:plate_track_ai/shared/widgets/soft_card.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/shared/widgets/weight_card.dart';

/// The home screen: weight, today's intake, and the last few meals. Each
/// section is a door to the screen that holds the detail — weight history,
/// calorie history, the full meal list.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  /// How many meals the dashboard shows before pointing at the full list.
  static const int recentMealCount = 3;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FoodStorageService _storageService = FoodStorageService();
  final FoodRecognitionService _recognitionService = FoodRecognitionService();
  final UserProfileService _userProfileService = UserProfileService();

  List<FoodItem> _recentFoodItems = [];
  bool _isLoading = true;
  DayTotals _today = const DayTotals();
  UserProfile? _profile;

  /// Daily targets from the profile's TDEE, or null until one exists.
  Map<String, double>? _targets;

  late final LocalDataObserver _dataObserver;

  @override
  void initState() {
    super.initState();
    _dataObserver = LocalDataObserver(
      onChanged: _loadDashboardData,
      changes: [
        _storageService.onDataChanged,
        _userProfileService.onDataChanged,
      ],
    );
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _recognitionService.initialize();

    await _storageService.initialize();
    if (!mounted) return;

    await _loadDashboardData();
  }

  @override
  void dispose() {
    _dataObserver.dispose();
    _recognitionService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    try {
      await _userProfileService.initialize();

      final today = DateTime.now();
      final todaysItems = await _storageService.getFoodItemsByDate(today);

      final allItems = await _storageService.getAllFoodItems();
      allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _recentFoodItems = allItems
          .take(DashboardScreen.recentMealCount)
          .toList();
      _today = DayTotals.of(todaysItems);
      _profile = _userProfileService.currentProfile;
      _targets = _userProfileService.getNutritionTargets();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _push(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadDashboardData());
  }

  void _openWeightHistory() => _push(const WeightHistoryScreen());
  void _openStats() => _push(const NutritionStatsScreen());
  void _openMeals() => _push(const MealHistoryScreen());
  void _openProfile() => _push(const ProfileManagementScreen());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openProfile,
            tooltip: 'profile_tab'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // 96 clears the floating action button; pagePadding adds the
              // system navigation inset underneath that.
              padding: AppDimens.pagePadding(context, bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_profile != null) ...[
                    SectionHeader(
                      'your_weight'.tr(),
                      trailing: SeeAllLink(onTap: _openWeightHistory),
                    ),
                    WeightCard(
                      current: _profile!.weight,
                      start: _profile!.effectiveStartWeight,
                      goal: _profile!.goalWeight,
                      progress: _profile!.weightProgress,
                      onTap: _openWeightHistory,
                    ),
                    const SizedBox(height: AppDimens.sectionGap),
                  ],

                  // Calorie history lives behind the same card and link.
                  SectionHeader(
                    'your_calories'.tr(),
                    trailing: SeeAllLink(onTap: _openStats),
                  ),
                  _SummaryCard(
                    totals: _today,
                    targets: _targets,
                    onTap: _openStats,
                  ),
                  const SizedBox(height: AppDimens.sectionGap),

                  buildFoodItemSection(
                    context: context,
                    items: _recentFoodItems,
                    refreshCallback: _loadDashboardData,
                    trailing: SeeAllLink(onTap: _openMeals),
                    // The full list groups by day and shows the time; here
                    // the meals are simply the latest few.
                    showTimestamp: false,
                  ),
                ],
              ),
            ),
    );
  }
}

/// The gauge-and-macros panel.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totals, required this.targets, this.onTap});

  final DayTotals totals;
  final Map<String, double>? targets;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // With no profile there is no TDEE, so every target is zero: the gauge and
    // the bars then render as empty tracks showing the raw amounts eaten.
    double target(String key) => targets?[key] ?? 0;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            // Keeps the arc from touching the card's rounded corners.
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CalorieGauge(
              consumed: totals.calories,
              target: target('calories'),
            ),
          ),
          const SizedBox(height: 18),
          MacroBars(
            macros: [
              MacroProgress(
                macro: Macro.protein,
                grams: totals.protein,
                target: target('protein'),
              ),
              MacroProgress(
                macro: Macro.carbs,
                grams: totals.carbs,
                target: target('carbs'),
              ),
              MacroProgress(
                macro: Macro.fat,
                grams: totals.fat,
                target: target('fat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
