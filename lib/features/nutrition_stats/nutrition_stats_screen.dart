import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:intl/intl.dart';

class NutritionStatsScreen extends StatefulWidget {
  const NutritionStatsScreen({Key? key}) : super(key: key);

  @override
  State<NutritionStatsScreen> createState() => _NutritionStatsScreenState();
}

class _NutritionStatsScreenState extends State<NutritionStatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;
  final FoodStorageService _storageService = FoodStorageService();
  
  // Data states
  List<FoodItem> _todaysFoodItems = [];
  List<List<FoodItem>> _weeklyFoodItems = [];
  bool _isLoading = true;
  
  // Nutrition summary
  double _totalCalories = 0;
  double _totalProtein = 0;
  double _totalCarbs = 0;
  double _totalFat = 0;
  
  // Target values (these could be configurable in a settings screen)
  final double _targetCalories = 2000;
  final double _targetProtein = 80;
  final double _targetCarbs = 250;
  final double _targetFat = 70;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    
    // Load food data
    _loadFoodData();
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
        title: Text(AppStrings.statsTab),
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
        children: [
          _buildDailyStatsTab(),
          _buildWeeklyStatsTab(),
        ],
      ),
    );
  }

  Widget _buildDailyStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
    );
  }

  Widget _buildWeeklyStatsTab() {
    return SingleChildScrollView(
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.caloriesConsumed,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${consumedCalories.toInt()} / ${targetCalories.toInt()} kcal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercentage.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progressPercentage * 100).toInt()}% of daily goal',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
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
            color: Colors.grey.withOpacity(0.1),
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
        elevation: 0,
        color: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.no_food,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No food items recorded today',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to camera tab - this requires a more complex implementation
                    // Here we just provide a placeholder
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please navigate to the Camera tab to add food items'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Add food'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todaysFoodItems.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = _todaysFoodItems[index];
        final timeString = DateFormat('h:mm a').format(item.timestamp);
        
        // Calculate actual calories based on per 100g value and mass
        final double mass = item.nutritionFacts.mass ?? 100.0;
        final int actualCalories = ((item.calories * mass) / 100.0).toInt();
        
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            item.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          subtitle: Text('$timeString · ${mass.toInt()}g'),
          trailing: Text(
            '$actualCalories kcal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          onLongPress: () => _showDeleteDialog(item),
        );
      },
    );
  }
  
  Future<void> _showDeleteDialog(FoodItem item) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete food item?'),
          content: Text('Do you want to delete "${item.name}" from your records?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _storageService.deleteFoodItem(item.id);
                Navigator.of(context).pop();
                _loadFoodData(); // Refresh data
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
            color: Colors.grey.withOpacity(0.1),
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
                color: Colors.grey[300],
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
    int daysWithData = 0;
    
    for (final dailyItems in _weeklyFoodItems) {
      if (dailyItems.isNotEmpty) {
        daysWithData++;
        double dailyCalories = 0;
        double dailyProtein = 0;
        
        for (final item in dailyItems) {
          // Calculate based on per 100g values and mass
          final double mass = item.nutritionFacts.mass ?? 100.0;
          dailyCalories += (item.calories * mass) / 100.0;
          dailyProtein += (item.nutritionFacts.protein * mass) / 100.0;
        }
        
        avgCalories += dailyCalories;
        avgProtein += dailyProtein;
      }
    }
    
    // Calculate averages only if we have data
    if (daysWithData > 0) {
      avgCalories /= daysWithData;
      avgProtein /= daysWithData;
    }

    return Row(
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
}