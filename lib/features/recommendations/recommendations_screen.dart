import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final FoodStorageService _storageService = FoodStorageService();
  bool _isLoading = false;
  
  // Nutrition summary for the past week
  double _avgCalories = 0;
  double _avgProtein = 0;
  double _avgCarbs = 0;
  double _avgFat = 0;
  
  // Target values (these could be configurable in a settings screen)
  final double _targetCalories = 2000;
  final double _targetProtein = 80;
  final double _targetCarbs = 250;
  final double _targetFat = 70;
  
  // List of personalized recommendations
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    // Initialize the service and load data once
    _storageService.initialize();
    _loadData();
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
            totalCalories += item.calories;
            totalProtein += item.nutritionFacts.protein;
            totalCarbs += item.nutritionFacts.carbohydrates;
            totalFat += item.nutritionFacts.fat;
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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      AppStrings.personalizedTips,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.basedOnDiet,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
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
              color: Colors.grey[800],
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