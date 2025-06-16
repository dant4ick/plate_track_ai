import 'package:flutter/material.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/dashboard/dashboard_screen.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_stats_screen.dart';
import 'package:plate_track_ai/features/recommendations/recommendations_screen.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/features/profile/profile_management_screen.dart';
import 'package:plate_track_ai/features/food_recognition/food_camera_screen.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';

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

  // Register User Profile adapters
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(UserProfileAdapter());
  }

  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(GenderAdapter());
  }

  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ActivityLevelAdapter());
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
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final UserProfileService _userProfileService = UserProfileService();
  bool _isLoading = true;
  bool _hasUserProfile = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('AppInitializer: Starting initialization...');
      await _userProfileService.initialize();
      print('AppInitializer: UserProfileService initialized, hasUserProfile: ${_userProfileService.hasUserProfile}');
      if (mounted) {
        setState(() {
          _hasUserProfile = _userProfileService.hasUserProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onProfileSetupComplete() async {
    try {
      print('AppInitializer: Profile setup completed, re-initializing service...');
      
      // Add a small delay to ensure the profile was saved
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Re-initialize the service to check if profile was saved
      await _userProfileService.initialize();
      print('AppInitializer: Service re-initialized, hasUserProfile: ${_userProfileService.hasUserProfile}');
      
      if (mounted) {
        setState(() {
          _hasUserProfile = _userProfileService.hasUserProfile;
        });
      }
    } catch (e) {
      print('AppInitializer: Error in onProfileSetupComplete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AppInitializer: Building - isLoading: $_isLoading, hasUserProfile: $_hasUserProfile');
    
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading Plate Track...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasUserProfile) {
      return UserSetupScreen(
        onComplete: _onProfileSetupComplete,
      );
    }

    return const HomeScreen();
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
        return const DashboardScreen();
      case 1:
        return const NutritionStatsScreen();
      case 2:
        return const RecommendationsScreen();
      case 3:
        return const ProfileManagementScreen();
      default:
        return const DashboardScreen();
    }
  }

  void _navigateToFoodCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodCameraScreen(),
      ),
    ).then((result) {
      // Refresh the current screen when coming back from camera
      // This is especially useful for the dashboard to show new food items
      if (result == true) {
        setState(() {
          // This will trigger a rebuild and refresh of the current screen
        });
      }
    });
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isMain = false}) {
    final isSelected = index == _selectedIndex;
    
    if (isMain) {
      return Expanded(
        flex: 2, // Give the main button more space
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context).colorScheme.primary,
            child: InkWell(
              onTap: _navigateToFoodCamera,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey,
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected 
                    ? Theme.of(context).colorScheme.primary 
                    : Colors.grey,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 110,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildNavItem(0, Icons.home, AppStrings.homeTab),
                _buildNavItem(1, Icons.bar_chart, AppStrings.statsTab),
                _buildNavItem(-1, Icons.camera_alt, 'Scan Food', isMain: true),
                _buildNavItem(2, Icons.lightbulb, AppStrings.recommendationsTab),
                _buildNavItem(3, Icons.person, AppStrings.profileTab),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
