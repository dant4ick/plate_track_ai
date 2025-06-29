import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/standard_app_bar.dart';
import 'package:plate_track_ai/core/services/food_recognition_service.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'dart:async';

import 'package:plate_track_ai/shared/widgets/food_items.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FoodStorageService _storageService = FoodStorageService();
  final FoodRecognitionService _recognitionService = FoodRecognitionService();
  final UserProfileService _userProfileService = UserProfileService();
  List<FoodItem> _recentFoodItems = [];
  bool _isLoading = true;
  double _todayCalories = 0;
  int _todayItemsCount = 0;

  // Target values (will be loaded from user profile or use defaults)
  double _targetCalories = 2000;

  // Stream subscription for data changes
  late StreamSubscription<void> _dataChangeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize recognition service
    _recognitionService.initialize();

    // Initialize user profile service and load targets
    await _userProfileService.initialize();
    _loadUserTargets();

    // Initialize storage service and listen to data changes
    await _storageService.initialize();
    _dataChangeSubscription = _storageService.onDataChanged.listen((_) {
      // Refresh dashboard data when storage data changes
      _loadDashboardData();
    });

    // Load dashboard data
    _loadDashboardData();
  }

  void _loadUserTargets() {
    final targets = _userProfileService.getNutritionTargets();
    if (targets != null && mounted) {
      setState(() {
        _targetCalories = targets['calories']!;
      });
    }
  }

  @override
  void dispose() {
    _dataChangeSubscription.cancel();
    _recognitionService.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load today's food items
      final today = DateTime.now();
      final todayItems = await _storageService.getFoodItemsByDate(today);

      // Load recent items (last 5 items from all days)
      final allItems = await _storageService.getAllFoodItems();
      allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _recentFoodItems = allItems.take(5).toList();

      // Calculate today's stats
      _todayCalories = todayItems.fold(0.0, (sum, item) {
        final double mass = item.nutritionFacts.mass ?? 100.0;
        final double actualCalories = (item.calories * mass) / 100.0;
        return sum + actualCalories;
      });
      _todayItemsCount = todayItems.length;
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        onRefresh: _loadDashboardData,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section
                      _buildWelcomeCard(),

                      const SizedBox(height: 24),

                      // Quick stats
                      _buildQuickStatsCard(),

                      const SizedBox(height: 24),

                      // Recent items
                      _buildRecentItemsSection(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildWelcomeCard() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'good_morning'.tr();
    } else if (hour < 17) {
      greeting = 'good_afternoon'.tr();
    } else {
      greeting = 'good_evening'.tr();
    }

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
              Text(
                greeting,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'dashboard_welcome_message'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    final double calorieProgress = _todayCalories / _targetCalories;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'todays_summary'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Calorie progress bar
            _buildCalorieProgress(calorieProgress),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'items'.tr(),
                    '$_todayItemsCount',
                    'tracked'.tr(),
                    Icons.restaurant,
                    Colors.green[400]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'goal'.tr(),
                    '${(calorieProgress * 100).toInt()}%',
                    'completed'.tr(),
                    Icons.track_changes,
                    calorieProgress >= 1.0
                        ? Colors.green[400]!
                        : Colors.orange[400]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieProgress(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'calories'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${_todayCalories.toInt()} / ${_targetCalories.toInt()} ${'kcal'.tr()}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green[400]! : Colors.red[400]!,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItemsSection() {
    return buildFoodItemSection(
      context: context,
      items: _recentFoodItems,
      refreshCallback: _loadDashboardData,
    );
  }
}
