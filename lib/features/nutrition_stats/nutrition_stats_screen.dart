import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';
import 'package:intl/intl.dart';

class NutritionStatsScreen extends StatefulWidget {
  const NutritionStatsScreen({Key? key}) : super(key: key);

  @override
  State<NutritionStatsScreen> createState() => _NutritionStatsScreenState();
}

class _NutritionStatsScreenState extends State<NutritionStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FoodStorageService _storageService = FoodStorageService();
  final UserProfileService _userProfileService = UserProfileService();
  
  // Data states
  List<FoodItem> _todaysFoodItems = [];
  List<List<FoodItem>> _weeklyFoodItems = [];
  bool _isLoading = true;
  
  // Nutrition summary
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  
  // Target values (will be loaded from user profile or use defaults)
  double _targetCalories = 2000;
  double _targetProtein = 80;
  double _targetCarbs = 250;
  double _targetFat = 70;

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
      _targetProtein = targets['protein']!;
      _targetCarbs = targets['carbohydrates']!;
      _targetFat = targets['fat']!;
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
    } catch (e) {
      print('Error loading food data: $e');
      // Use sample data as fallback
      _todaysFoodItems = [];
      _weeklyFoodItems = List.generate(7, (_) => []);
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
      _totalCarbs += (item.nutritionFacts.carbohydrates * mass) / 100.0;
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
        appBar: AppBar(
          title: Text(AppStrings.statsTab),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: AppLogoWithText(
          text: AppStrings.statsTab,
          logoSize: 24,
          fontSize: 18,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFoodData,
            tooltip: 'Refresh data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppStrings.dailyStats),
            Tab(text: AppStrings.weeklyStats),
          ],
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
        children: [
          _buildDailyStatsTab(),
          _buildWeeklyStatsTab(),
        ],
      ),
    );
  }

  Widget _buildDailyStatsTab() {
    return RefreshIndicator(
      onRefresh: _loadFoodData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
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
            AppStrings.nutrientBreakdown,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildNutrientPieChart(),
          
          const SizedBox(height: 24),
          
          // Food items list
          Text(
            'Today\'s Food',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weekly calorie line chart
            Text(
              'Weekly Calories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyCalorieChart(),
            
            const SizedBox(height: 24),
            
            // Weekly nutrient averages
            Text(
              'Weekly Averages',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyAveragesCards(),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    color: Colors.red[400]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: Colors.red[400]!,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.caloriesConsumed,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${consumedCalories.toInt()} / ${targetCalories.toInt()} kcal',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[400],
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
                backgroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[700] 
                    : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.red[400]!,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progressPercentage * 100).toInt()}% of daily goal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressPercentage >= 1.0 
                        ? Colors.green[400]!.withOpacity(0.1)
                        : Colors.orange[400]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    progressPercentage >= 1.0 ? 'Goal reached!' : 'Keep going!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: progressPercentage >= 1.0 
                              ? Colors.green[600]
                              : Colors.orange[600],
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
        color: Colors.purple[400]!,
        value: _totalProtein,
        title: '${_totalProtein.toInt()}g',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.amber[700]!,
        value: _totalCarbs,
        title: '${_totalCarbs.toInt()}g',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.blue[400]!,
        value: _totalFat,
        title: '${_totalFat.toInt()}g',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
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
                      'No nutrition data for today',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem(Colors.purple[400]!, AppStrings.protein, '${_totalProtein.toInt()}g'),
              const SizedBox(height: 12),
              _buildLegendItem(Colors.amber[700]!, AppStrings.carbs, '${_totalCarbs.toInt()}g'),
              const SizedBox(height: 12),
              _buildLegendItem(Colors.blue[400]!, AppStrings.fat, '${_totalFat.toInt()}g'),
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
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildFoodItemsList() {
    if (_todaysFoodItems.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[400]!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No food items recorded today',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your meals to see detailed nutrition statistics!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  // Navigate to camera - show a helpful message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Use the camera button at the bottom to start tracking meals'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Start Tracking'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todaysFoodItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _todaysFoodItems[index];
        
        return FoodItemCard(
          item: item,
          onDelete: () => _showDeleteDialog(item),
          showDeleteButton: true,
          timeFormat: 'h:mm a',
        );
      },
    );
  }

  
  Future<void> _showDeleteDialog(FoodItem item) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: isDark ? Colors.red[300] : Colors.red[400],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Food Item',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${item.name}" from your nutrition records?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.orange[900]?.withOpacity(0.3) : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.orange[600]! : Colors.orange[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: isDark ? Colors.orange[300] : Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.orange[200] : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _storageService.deleteFoodItem(item.id);
                Navigator.of(context).pop();
                _loadFoodData(); // Refresh data
                
                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[400],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Food item deleted successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildWeeklyCalorieChart() {
    // Calculate weekly calorie data
    final List<double> calorieData = [];
    for (final dailyItems in _weeklyFoodItems) {
      double dailyCalories = 0;
      for (final item in dailyItems) {
        // Calculate actual calories based on per 100g value and mass
        final double mass = item.nutritionFacts.mass ?? 100.0;
        dailyCalories += (item.calories * mass) / 100.0;
      }
      calorieData.add(dailyCalories);
    }
    
    // Get day names for the last 7 days
    final weekDays = [];
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day - i);
      weekDays.add(DateFormat('E').format(date)); // 'Mon', 'Tue', etc.
    }
    
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(calorieData),
          minY: 0,
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: calorieData[index],
                  color: index == 6 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      weekDays[value.toInt()],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value % 500 != 0) return const SizedBox();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 500,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[600] 
                    : Colors.grey[300],
                strokeWidth: 1,
              );
            },
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
  
  double _calculateMaxY(List<double> values) {
    double max = 0;
    for (final value in values) {
      if (value > max) max = value;
    }
    // Round up to nearest 500 and add some padding
    return ((max / 500).ceil() * 500 + 500).clamp(1000, 5000).toDouble();
  }
  
  Widget _buildWeeklyAveragesCards() {
    // Calculate weekly averages
    double avgCalories = 0;
    double avgProtein = 0;
    double avgCarbs = 0;
    double avgFat = 0;
    int daysWithData = 0;
    
    for (final dailyItems in _weeklyFoodItems) {
      if (dailyItems.isNotEmpty) {
        daysWithData++;
        double dailyCalories = 0;
        double dailyProtein = 0;
        double dailyCarbs = 0;
        double dailyFat = 0;
        
        for (final item in dailyItems) {
          // Calculate based on per 100g values and mass
          final double mass = item.nutritionFacts.mass ?? 100.0;
          dailyCalories += (item.calories * mass) / 100.0;
          dailyProtein += (item.nutritionFacts.protein * mass) / 100.0;
          dailyCarbs += (item.nutritionFacts.carbohydrates * mass) / 100.0;
          dailyFat += (item.nutritionFacts.fat * mass) / 100.0;
        }
        
        avgCalories += dailyCalories;
        avgProtein += dailyProtein;
        avgCarbs += dailyCarbs;
        avgFat += dailyFat;
      }
    }
    
    // Calculate averages only if we have data
    if (daysWithData > 0) {
      avgCalories /= daysWithData;
      avgProtein /= daysWithData;
      avgCarbs /= daysWithData;
      avgFat /= daysWithData;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAverageCard(
                AppStrings.calories, 
                avgCalories.toInt().toString(), 
                'kcal/day',
                Colors.red[400]!,
                Icons.local_fire_department,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAverageCard(
                AppStrings.protein, 
                avgProtein.toInt().toString(), 
                'g/day',
                Colors.purple[400]!,
                Icons.fitness_center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildAverageCard(
                AppStrings.carbs, 
                avgCarbs.toInt().toString(), 
                'g/day',
                Colors.amber[700]!,
                Icons.grain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAverageCard(
                AppStrings.fat, 
                avgFat.toInt().toString(), 
                'g/day',
                Colors.blue[400]!,
                Icons.opacity,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAverageCard(String title, String value, String unit, Color color, IconData icon) {
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
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              unit,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    String message;
    IconData icon;
    
    if (_totalCalories < _targetCalories * 0.5) {
      message = 'You\'re off to a good start today!';
      icon = Icons.emoji_events;
    } else if (_totalCalories >= _targetCalories) {
      message = 'Great job reaching your calorie goal!';
      icon = Icons.check_circle;
    } else {
      message = 'Keep up the great work!';
      icon = Icons.trending_up;
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nutrition Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
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