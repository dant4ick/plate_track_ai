import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/food_recognition/food_camera_screen.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_stats_screen.dart';
import 'package:plate_track_ai/features/recommendations/recommendations_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';

// TODO: fix night mode fields being bright

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive Adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(FoodItemAdapter());
  }
  
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(NutritionFactsAdapter());
  }
  
  // Register DateTime adapter (needed for timestamp field)
  if (!Hive.isAdapterRegistered(16)) {
    Hive.registerAdapter(DateTimeAdapter());
  }
  
  runApp(const PlateTrackApp());
}

// Custom DateTime adapter for Hive
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final typeId = 16;

  @override
  DateTime read(BinaryReader reader) {
    return DateTime.fromMillisecondsSinceEpoch(reader.readInt());
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.millisecondsSinceEpoch);
  }
}

class PlateTrackApp extends StatelessWidget {
  const PlateTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Uses the device's theme settings
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  // Remove the static const List to create fresh instances when tabs are switched
  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const FoodCameraScreen();
      case 1:
        return const NutritionStatsScreen();
      case 2:
        return const RecommendationsScreen();
      default:
        return const FoodCameraScreen();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreenForIndex(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: AppStrings.cameraTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: AppStrings.statsTab,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: AppStrings.recommendationsTab,
          ),
        ],
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 8,
      ),
    );
  }
}
