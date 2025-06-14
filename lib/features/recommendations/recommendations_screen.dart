import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

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
  
  // List of personalized recommendations
  List<Map<String, dynamic>> _recommendations = [];

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
        _targetCarbs = targets['carbohydrates']!;
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
            totalCarbs += (item.nutritionFacts.carbohydrates * mass) / 100.0;
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
      print('Error loading nutrition data: $e');
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
    _recommendations = [];
    
    // Calorie recommendation
    if (_avgCalories < _targetCalories * 0.8) {
      _recommendations.add({
        'title': 'Increase Calorie Intake',
        'description': 'Your average calorie intake (${_avgCalories.toInt()} kcal) is below your target (${_targetCalories.toInt()} kcal). Consider adding more nutrient-dense foods to your diet.',
        'icon': Icons.add_circle,
        'color': Colors.orange[700],
      });
    } else if (_avgCalories > _targetCalories * 1.2) {
      _recommendations.add({
        'title': 'Reduce Calorie Intake',
        'description': 'Your average calorie intake (${_avgCalories.toInt()} kcal) is above your target (${_targetCalories.toInt()} kcal). Consider reducing portion sizes or opting for lower-calorie alternatives.',
        'icon': Icons.remove_circle,
        'color': Colors.red[700],
      });
    }
    
    // Protein recommendation
    if (_avgProtein < _targetProtein * 0.8) {
      _recommendations.add({
        'title': 'Increase Protein Intake',
        'description': 'Your protein intake is low. Try to include more lean meats, fish, eggs, legumes or dairy products in your diet.',
        'icon': Icons.fitness_center,
        'color': Colors.purple[700],
      });
    }
    
    // Carbs recommendation
    double carbRatio = _avgCarbs / _targetCarbs;
    if (carbRatio > 1.3) {
      _recommendations.add({
        'title': 'Reduce Simple Carbohydrates',
        'description': 'Your carbohydrate intake is relatively high. Try to reduce simple carbs like sugars and refined grains, and opt for complex carbohydrates like whole grains.',
        'icon': Icons.grain,
        'color': Colors.amber[700],
      });
    }
    
    // Fat recommendation
    if (_avgFat > _targetFat * 1.2) {
      _recommendations.add({
        'title': 'Monitor Fat Intake',
        'description': 'Your fat intake is above the recommended level. Focus on healthy fats from sources like olive oil, avocados, and nuts while reducing saturated fats.',
        'icon': Icons.opacity,
        'color': Colors.blue[700],
      });
    }
    
    // General healthy eating recommendation
    _recommendations.add({
      'title': 'Stay Hydrated',
      'description': 'Don\'t forget to drink enough water throughout the day. Proper hydration helps with digestion and nutrient absorption.',
      'icon': Icons.water_drop,
      'color': Colors.blue[700],
    });
    
    // If no specific recommendations, add some general ones
    if (_recommendations.length < 3) {
      _recommendations.add({
        'title': 'Eat a Variety of Foods',
        'description': 'Try to include a diverse range of foods in your diet to ensure you get all the nutrients your body needs.',
        'icon': Icons.diversity_1,
        'color': Colors.teal[700],
      });
      
      _recommendations.add({
        'title': 'Regular Meal Pattern',
        'description': 'Aim to eat at regular intervals throughout the day to maintain energy levels and prevent overeating.',
        'icon': Icons.schedule,
        'color': Colors.indigo[700],
      });
    }
  }
  
  void _useDefaultRecommendations() {
    _recommendations = [
      {
        'title': 'Balance Your Macronutrients',
        'description': 'Aim for a balanced intake of protein, carbohydrates, and fats in your diet for optimal nutrition.',
        'icon': Icons.balance,
        'color': Colors.purple[700],
      },
      {
        'title': 'Stay Hydrated',
        'description': 'Don\'t forget to drink enough water throughout the day. Proper hydration helps with digestion and nutrient absorption.',
        'icon': Icons.water_drop,
        'color': Colors.blue[700],
      },
      {
        'title': 'Portion Control',
        'description': 'Pay attention to portion sizes to help maintain a healthy calorie balance.',
        'icon': Icons.pie_chart,
        'color': Colors.orange[700],
      },
      {
        'title': 'Eat More Whole Foods',
        'description': 'Focus on unprocessed or minimally processed foods for better nutritional value.',
        'icon': Icons.restaurant,
        'color': Colors.green[700],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _storageService.foodBoxListenable,
      builder: (context, box, child) {
        // Don't call _loadData() here - that was causing the error
        // Instead, call it inside didUpdateWidget or use a useEffect pattern
        
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.recommendationsTab),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadData,
                tooltip: 'Refresh data',
              ),
            ],
          ),
          body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
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
                      Text(
                        AppStrings.improveNutrition,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Recommendations list
                      _buildRecommendationsList(),
                    ],
                  ),
                ),
              ),
        );
      },
    );
  }
  
  // Override didUpdateWidget to load data when box changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the dependencies of this widget change,
    // including when the ValueListenable emits a new value
    _loadData();
  }
  
  Widget _buildHeaderSection() {
    String message;
    IconData icon;
    Color iconColor;
    
    if (_avgCalories == 0) {
      message = 'Start tracking your meals to get personalized tips!';
      icon = Icons.restaurant_menu;
      iconColor = Colors.blue[400]!;
    } else if (_avgCalories < _targetCalories * 0.8) {
      message = 'Your nutrition data looks good. Keep making healthy choices!';
      icon = Icons.trending_up;
      iconColor = Colors.green[400]!;
    } else if (_avgCalories > _targetCalories * 1.2) {
      message = 'Consider moderating your calorie intake for better balance.';
      icon = Icons.info;
      iconColor = Colors.orange[400]!;
    } else {
      message = 'You\'re doing great with your nutrition tracking!';
      icon = Icons.check_circle;
      iconColor = Colors.green[400]!;
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
              iconColor.withOpacity(0.1),
              iconColor.withOpacity(0.05),
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
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.personalizedTips,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: iconColor,
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
  
  Widget _buildInsightsCard() {
    // Calculate percentages of daily targets
    final proteinPercentage = (_avgProtein / _targetProtein).clamp(0.0, 1.5);
    final carbsPercentage = (_avgCarbs / _targetCarbs).clamp(0.0, 1.5);
    final fatPercentage = (_avgFat / _targetFat).clamp(0.0, 1.5);

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
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Nutrition Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildNutrientProgressBar(
              context, 
              'Protein', 
              proteinPercentage, 
              '${(proteinPercentage * 100).toInt()}% of daily goal',
              Colors.purple[400]!,
            ),
            const SizedBox(height: 12),
            
            _buildNutrientProgressBar(
              context, 
              'Carbohydrates', 
              carbsPercentage, 
              '${(carbsPercentage * 100).toInt()}% of daily goal',
              Colors.amber[700]!,
            ),
            const SizedBox(height: 12),
            
            _buildNutrientProgressBar(
              context, 
              'Fat', 
              fatPercentage, 
              '${(fatPercentage * 100).toInt()}% of daily goal',
              Colors.blue[400]!,
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
    String focusMessage = 'Focus on maintaining your balanced diet.';
    
    // Determine the nutrient that needs the most attention
    if (_avgProtein < _targetProtein * 0.7) {
      focusMessage = 'Focus today: Try to increase your protein intake by adding more lean meats, fish, eggs, or plant-based proteins.';
    } else if (_avgCalories < _targetCalories * 0.7) {
      focusMessage = 'Focus today: Your calorie intake is low. Try adding more nutrient-dense foods to your diet.';
    } else if (_avgCalories > _targetCalories * 1.3) {
      focusMessage = 'Focus today: Your calorie intake is above target. Consider moderating portion sizes.';
    }
    
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey[200] 
                  : Colors.grey[800],
            ),
        children: [
          const TextSpan(
            text: 'Focus today: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: focusMessage.replaceFirst('Focus today: ', ''),
          ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              progressText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
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
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _recommendations[index];
        return _buildRecommendationCard(
          context,
          title: item['title'] as String,
          description: item['description'] as String,
          icon: item['icon'] as IconData,
          color: item['color'] as Color,
        );
      },
    );
  }
  
  Widget _buildRecommendationCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Learn More',
              onPressed: () {
                // TODO: Navigate to detailed recommendation screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('More details about "$title" will be available soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              isSecondary: true,
              icon: Icons.info_outline,
            ),
          ],
        ),
      ),
    );
  }
}