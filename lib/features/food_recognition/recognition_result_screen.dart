import 'dart:io';
import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';

class RecognitionResultScreen extends StatefulWidget {
  final File imageFile;
  final FoodItem foodItem;
  final Function(FoodItem) onSave;

  const RecognitionResultScreen({
    Key? key,
    required this.imageFile,
    required this.foodItem,
    required this.onSave,
  }) : super(key: key);

  @override
  State<RecognitionResultScreen> createState() => _RecognitionResultScreenState();
}

class _RecognitionResultScreenState extends State<RecognitionResultScreen> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _massController;
  
  // Store the per 100g values from the ML model
  late double _caloriesPer100g;
  late double _proteinPer100g;
  late double _carbsPer100g;
  late double _fatPer100g;
  double _currentMass = 100.0;
  
  @override
  void initState() {
    super.initState();
    
    // Store the per 100g values (the FoodItem now contains per 100g values)
    _caloriesPer100g = widget.foodItem.calories;
    _proteinPer100g = widget.foodItem.nutritionFacts.protein;
    _carbsPer100g = widget.foodItem.nutritionFacts.carbohydrates;
    _fatPer100g = widget.foodItem.nutritionFacts.fat;
    
    // Initialize with the detected mass or default to 100g
    _currentMass = widget.foodItem.nutritionFacts.mass ?? 100.0;
    
    // Calculate the initial total values based on the current mass
    final double totalCalories = _calculateTotalValue(_caloriesPer100g, _currentMass);
    final double totalProtein = _calculateTotalValue(_proteinPer100g, _currentMass);
    final double totalCarbs = _calculateTotalValue(_carbsPer100g, _currentMass);
    final double totalFat = _calculateTotalValue(_fatPer100g, _currentMass);
    
    // Initialize controllers with calculated total values
    _nameController = TextEditingController(text: widget.foodItem.name);
    _caloriesController = TextEditingController(text: totalCalories.toInt().toString());
    _proteinController = TextEditingController(text: totalProtein.toInt().toString());
    _carbsController = TextEditingController(text: totalCarbs.toInt().toString());
    _fatController = TextEditingController(text: totalFat.toInt().toString());
    _massController = TextEditingController(text: _currentMass.toInt().toString());
    
    // Add listener to mass controller to update nutrition values when mass changes
    _massController.addListener(_updateNutritionValues);
  }
  
  @override
  void dispose() {
    // Remove listener before disposing controllers
    _massController.removeListener(_updateNutritionValues);
    
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _massController.dispose();
    super.dispose();
  }
  
  // Calculate total value based on per 100g value and current mass
  double _calculateTotalValue(double per100gValue, double mass) {
    return (per100gValue * mass) / 100.0;
  }
  
  // Update nutrition values when mass changes
  void _updateNutritionValues() {
    // Parse the new mass value
    double? newMass = double.tryParse(_massController.text);
    if (newMass != null && newMass > 0) {
      setState(() {
        _currentMass = newMass;
        
        // Calculate new total values based on the updated mass
        final double totalCalories = _calculateTotalValue(_caloriesPer100g, _currentMass);
        final double totalProtein = _calculateTotalValue(_proteinPer100g, _currentMass);
        final double totalCarbs = _calculateTotalValue(_carbsPer100g, _currentMass);
        final double totalFat = _calculateTotalValue(_fatPer100g, _currentMass);
        
        // Update text controllers (without triggering their own listeners)
        _caloriesController.text = totalCalories.toInt().toString();
        _proteinController.text = totalProtein.toInt().toString();
        _carbsController.text = totalCarbs.toInt().toString();
        _fatController.text = totalFat.toInt().toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review and adjust the nutrition information, then save when ready'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food image
            Hero(
              tag: 'food_image',
              child: Container(
                height: 240,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: FileImage(widget.imageFile),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            
            // Editable food details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  _buildStatusCard(context),
                  
                  const SizedBox(height: 16),
                  
                  // Food name field
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Food Name',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.food_bank, color: Theme.of(context).colorScheme.primary),
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mass field card
                  Card(
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
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.scale,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Portion Size',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _massController,
                            decoration: InputDecoration(
                              labelText: "Mass (grams)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixText: "g",
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Nutrition facts header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.nutritionFacts,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    "Values calculated based on portion size",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nutrition value cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutritionCard(
                          controller: _caloriesController,
                          label: AppStrings.calories,
                          icon: Icons.local_fire_department,
                          suffix: "kcal",
                          color: Colors.red[400]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutritionCard(
                          controller: _proteinController,
                          label: AppStrings.protein,
                          icon: Icons.fitness_center,
                          suffix: "g",
                          color: Colors.purple[400]!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildNutritionCard(
                          controller: _carbsController,
                          label: AppStrings.carbs,
                          icon: Icons.grain,
                          suffix: "g",
                          color: Colors.amber[700]!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNutritionCard(
                          controller: _fatController,
                          label: AppStrings.fat,
                          icon: Icons.opacity,
                          suffix: "g",
                          color: Colors.blue[400]!,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Tips section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.improveNutrition,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Recommendations
                  _buildRecommendationItem(
                    context,
                    "Good protein source, consider balancing with whole grains",
                    Icons.tips_and_updates,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildRecommendationItem(
                    context,
                    "Try adding more vegetables for additional fiber",
                    Icons.eco,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: AppStrings.retake,
                onPressed: () => Navigator.pop(context, true),
                isSecondary: true,
                icon: Icons.replay,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                text: AppStrings.saveResult,
                onPressed: _saveFoodItem,
                icon: Icons.save_alt,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutritionCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String suffix,
    required Color color,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  controller.text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    suffix,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
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

  void _saveFoodItem() {
    try {
      // Parse values from controllers
      final double mass = double.parse(_massController.text);
      // Validate that all fields have valid numbers
      double.parse(_caloriesController.text);
      double.parse(_proteinController.text);
      double.parse(_carbsController.text);
      double.parse(_fatController.text);
      
      // Create updated FoodItem object with total values based on the current mass
      final updatedFoodItem = FoodItem(
        id: widget.foodItem.id, // Preserve original ID if it exists
        name: _nameController.text,
        // Store the per 100g values for display consistency
        calories: _caloriesPer100g,
        nutritionFacts: NutritionFacts(
          protein: _proteinPer100g,
          carbohydrates: _carbsPer100g,
          fat: _fatPer100g,
          mass: mass,
        ),
        imagePath: widget.imageFile.path,
      );
      
      // Call the onSave callback
      widget.onSave(updatedFoodItem);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food item saved to your history'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Go back to previous screen with result to reset analyzing state
      Navigator.pop(context, true);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving food item: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusCard(BuildContext context) {
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
                  Icons.analytics,
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
                      'Food Analysis Complete',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review and adjust the nutrition information below',
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

  Widget _buildRecommendationItem(BuildContext context, String text, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}