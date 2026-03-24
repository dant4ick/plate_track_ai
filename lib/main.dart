import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/features/dashboard/dashboard_screen.dart';
import 'package:plate_track_ai/features/nutrition_stats/nutrition_stats_screen.dart';
import 'package:plate_track_ai/features/recommendations/recommendations_screen.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/features/profile/profile_management_screen.dart';
import 'package:plate_track_ai/features/food_recognition/food_camera_screen.dart';
import 'package:plate_track_ai/features/barcode_scan/barcode_scanner_screen.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/services/barcode_cache_service.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';
import 'package:plate_track_ai/shared/models/cached_barcode_product_adapter.dart';

// TODO: fix autorefresh in stats_tab after food recognition

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

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

  if (!Hive.isAdapterRegistered(5)) {
    Hive.registerAdapter(CachedBarcodeProductAdapter());
  }

  // Initialize barcode cache
  await BarcodeCacheService().initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const PlateTrackApp(),
    ),
  );
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
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Uses the device's theme settings
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
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
      await _userProfileService.initialize();
      if (mounted) {
        setState(() {
          _hasUserProfile = _userProfileService.hasUserProfile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onProfileSetupComplete() async {
    try {
      
      // Add a small delay to ensure the profile was saved
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Re-initialize the service to check if profile was saved
      await _userProfileService.initialize();
      
      if (mounted) {
        setState(() {
          _hasUserProfile = _userProfileService.hasUserProfile;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppInitializer: Error handling user setup completion: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
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
                'loading_plate_track'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  late AnimationController _dialController;
  late Animation<double> _aiAnim;
  late Animation<double> _barcodeAnim;
  late Animation<double> _overlayAnim;

  // True while animation value > 0 (opening, open, or closing)
  bool get _dialVisible => _dialController.value > 0;
  // Icon shows "close" when more than halfway open
  bool get _showCloseIcon => _dialController.value > 0.5;

  @override
  void initState() {
    super.initState();
    _dialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Rebuild on every animation frame so the overlay/button update smoothly
    _dialController.addListener(() => setState(() {}));

    _overlayAnim = CurvedAnimation(
      parent: _dialController,
      curve: Curves.easeOut,
    );
    _aiAnim = CurvedAnimation(
      parent: _dialController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );
    _barcodeAnim = CurvedAnimation(
      parent: _dialController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _dialController.dispose();
    super.dispose();
  }

  void _toggleDial() {
    if (_dialController.isDismissed) {
      _dialController.forward();
    } else {
      _dialController.reverse();
    }
  }

  void _closeDial() => _dialController.reverse();

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
      MaterialPageRoute(builder: (context) => const FoodCameraScreen()),
    ).then((result) {
      if (result == true) setState(() {});
    });
  }

  void _navigateToBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    ).then((result) {
      if (result == true) setState(() {});
    });
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  // ── Nav item ────────────────────────────────────────────────────────────────

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = index == _selectedIndex;
    return Expanded(
      flex: 2,
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
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
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

  // ── Main dial button ─────────────────────────────────────────────────────────

  Widget _buildMainDialButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.primary,
        child: InkWell(
          onTap: _toggleDial,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showCloseIcon ? Icons.close : Icons.camera_alt,
                key: ValueKey(_showCloseIcon),
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sub-button ───────────────────────────────────────────────────────────────
  //
  // The icon circle (48 px wide) must be centred horizontally over the main
  // button, which is itself centred on screen.  We achieve this by right-padding
  // the row so the right edge of the 48-px circle lands at
  //   (screenWidth / 2) + 24.
  // i.e. rightPadding = screenWidth - (screenWidth/2 + 24) = screenWidth/2 - 24.

  Widget _buildSubButton({
    required Animation<double> anim,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rightPadding = (screenWidth / 2 - 24.0).clamp(0.0, screenWidth);

    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: anim,
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(right: rightPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Label pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              // Icon circle — 48 × 48
              Material(
                elevation: 3,
                shape: const CircleBorder(),
                color: color,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // Total rendered height of the bottom nav bar (SafeArea padding + content)
    const navContentHeight = 110.0;
    final navTotalHeight = navContentHeight + bottomPadding;

    // Bottom nav bar — centre slot is a plain spacer; the real button lives in
    // the Stack above so it is never clipped and always on the correct Z layer.
    final bottomNav = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: navContentHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                _buildNavItem(0, Icons.home, 'home_tab'.tr()),
                _buildNavItem(1, Icons.bar_chart, 'stats_tab'.tr()),
                // Spacer matching the width slot of the main button
                const Expanded(flex: 3, child: SizedBox.shrink()),
                _buildNavItem(2, Icons.lightbulb, 'recommendations_tab'.tr()),
                _buildNavItem(3, Icons.person, 'profile_tab'.tr()),
              ],
            ),
          ),
        ),
      ),
    );

    // Stack Z-order (bottom → top):
    //  [0] Scaffold  — body + nav bar
    //  [1] Dim overlay — full screen, blocks nav-tab taps when dial is open
    //  [2] Sub-button: AI Scan
    //  [3] Sub-button: Barcode
    //  [4] Main dial button — always on top and tappable
    return Stack(
      children: [
        // [0] Scaffold
        Scaffold(
          body: _getScreenForIndex(_selectedIndex),
          bottomNavigationBar: bottomNav,
        ),

        // [1] Dim overlay — covers entire screen (including nav bar)
        if (_dialVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDial,
              behavior: HitTestBehavior.opaque,
              child: FadeTransition(
                opacity: _overlayAnim,
                child: Container(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
          ),

        // [2] Sub-button: AI Scan — just above the nav bar
        if (_dialVisible)
          Positioned(
            bottom: navTotalHeight + 12,
            left: 0,
            right: 0,
            child: _buildSubButton(
              anim: _aiAnim,
              icon: Icons.auto_awesome,
              label: 'scan_food_ai'.tr(),
              color: Theme.of(context).colorScheme.primary,
              onTap: () {
                _closeDial();
                _navigateToFoodCamera();
              },
            ),
          ),

        // [3] Sub-button: Barcode — one step higher
        if (_dialVisible)
          Positioned(
            bottom: navTotalHeight + 12 + 48 + 12,
            left: 0,
            right: 0,
            child: _buildSubButton(
              anim: _barcodeAnim,
              icon: Icons.barcode_reader,
              label: 'scan_barcode'.tr(),
              color: Theme.of(context).colorScheme.secondary,
              onTap: () {
                _closeDial();
                _navigateToBarcodeScanner();
              },
            ),
          ),

        // [4] Main dial button — centred over the spacer slot, always on top
        Positioned(
          bottom: bottomPadding + 19,
          left: 0,
          right: 0,
          child: Center(child: _buildMainDialButton()),
        ),
      ],
    );
  }
}
