import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:plate_track_ai/core/themes/app_colors.dart';
import 'package:plate_track_ai/core/themes/app_dimens.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';
import 'package:plate_track_ai/core/themes/theme_controller.dart';
import 'package:plate_track_ai/features/dashboard/dashboard_screen.dart';
import 'package:plate_track_ai/features/user_setup/user_setup_screen.dart';
import 'package:plate_track_ai/features/food_recognition/food_camera_screen.dart';
import 'package:plate_track_ai/features/barcode_scan/barcode_scanner_screen.dart';
import 'package:plate_track_ai/core/services/user_profile_service.dart';
import 'package:plate_track_ai/core/services/barcode_cache_service.dart';
import 'package:plate_track_ai/shared/widgets/app_logo.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:plate_track_ai/shared/models/food_item_adapters.dart';
import 'package:plate_track_ai/shared/models/user_profile_adapters.dart';
import 'package:plate_track_ai/shared/models/cached_barcode_product_adapter.dart';

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

  // Restore the stored theme choice so the first frame already wears it.
  await initThemePreference();

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
    return ValueListenableBuilder<ThemePreference>(
      valueListenable: themePreference,
      builder: (context, preference, _) {
        return MaterialApp(
          title: 'app_name'.tr(),
          debugShowCheckedModeBanner: false,
          theme: preference.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: preference.mode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: const AppInitializer(),
        );
      },
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
              AppLogo(size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'loading_plate_track'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasUserProfile) {
      return UserSetupScreen(onComplete: _onProfileSetupComplete);
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
  late AnimationController _dialController;
  late Animation<double> _aiAnim;
  late Animation<double> _barcodeAnim;
  late Animation<double> _overlayAnim;

  // True while animation value > 0 (opening, open, or closing)
  bool get _dialVisible => _dialController.value > 0;

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
    if (_dialController.status == AnimationStatus.forward ||
        _dialController.isCompleted) {
      _dialController.reverse();
    } else {
      _dialController.forward();
    }
  }

  void _closeDial() => _dialController.reverse();

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

  // ── Dial geometry ───────────────────────────────────────────────────────────
  //
  // The design puts the action button in the bottom-right corner rather than
  // centred in the nav bar, so the sub-buttons have to line up on *its* centre
  // line instead of the screen's.

  /// Edge of the squircle action button.
  static const double _fabSize = 60.0;

  /// Gap between the action button and the screen edge / nav bar.
  static const double _fabMargin = 16.0;

  /// Edge of a sub-button's icon circle.
  static const double _subSize = 48.0;

  /// Right inset that centres a [_subSize] circle over the action button.
  static const double _subRightInset = _fabMargin + _fabSize / 2 - _subSize / 2;

  // ── Main dial button ─────────────────────────────────────────────────────────

  Widget _buildMainDialButton() {
    final colors = Theme.of(context).colorScheme;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppDimens.radiusSquircle),
      color: colors.primary,
      shadowColor: AppPalette.of(context).shadow,
      child: InkWell(
        onTap: _toggleDial,
        borderRadius: BorderRadius.circular(AppDimens.radiusSquircle),
        child: SizedBox(
          width: _fabSize,
          height: _fabSize,
          // Keep the same glyph throughout: a 45-degree turn makes the plus
          // a close icon without a mid-animation shape change.
          child: Center(
            child: Transform.rotate(
              angle: _overlayAnim.value * math.pi / 4,
              child: Icon(Icons.add_rounded, color: colors.onPrimary, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  // ── Sub-button ───────────────────────────────────────────────────────────
  //
  // The icon circle is centred on the action button's vertical axis by insetting
  // the row from the right edge — see [_subRightInset].

  Widget _buildSubButton({
    required Animation<double> anim,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: anim,
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.only(right: _subRightInset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Label pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppPalette.of(context).shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Icon circle
              Material(
                elevation: 3,
                shape: const CircleBorder(),
                color: colors.primary,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: SizedBox(
                    width: _subSize,
                    height: _subSize,
                    child: Icon(icon, color: colors.onPrimary, size: 22),
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
    // With no nav bar, the dial sits directly above the system inset.
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final dialBottom = bottomInset + _fabMargin;

    // Stack Z-order (bottom → top):
    //  [0] The dashboard — the whole app surface now, and the child that sizes
    //      the stack. It brings its own Scaffold, so there is no outer one:
    //      the removed nav bar was the only reason this level ever had a
    //      Scaffold of its own.
    //  [1] Dim overlay — full screen, swallows taps while the dial is open
    //  [2] Sub-button: AI Scan
    //  [3] Sub-button: Barcode
    //  [4] Main dial button — always on top and tappable
    return Stack(
      children: [
        // [0] Dashboard
        const DashboardScreen(),

        // [1] Dim overlay
        if (_dialVisible)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDial,
              behavior: HitTestBehavior.opaque,
              child: FadeTransition(
                opacity: _overlayAnim,
                child: Container(color: AppColors.scrim),
              ),
            ),
          ),

        // [2] Sub-button: AI Scan — one step above the dial
        if (_dialVisible)
          Positioned(
            bottom: dialBottom + _fabSize + 12,
            left: 0,
            right: 0,
            child: _buildSubButton(
              anim: _aiAnim,
              icon: Icons.auto_awesome,
              label: 'scan_food_ai'.tr(),
              onTap: () {
                _closeDial();
                _navigateToFoodCamera();
              },
            ),
          ),

        // [3] Sub-button: Barcode — one step higher again
        if (_dialVisible)
          Positioned(
            bottom: dialBottom + _fabSize + 12 + _subSize + 12,
            left: 0,
            right: 0,
            child: _buildSubButton(
              anim: _barcodeAnim,
              icon: Icons.barcode_reader,
              label: 'scan_barcode'.tr(),
              onTap: () {
                _closeDial();
                _navigateToBarcodeScanner();
              },
            ),
          ),

        // [4] Main dial button — bottom-right, always on top and tappable
        Positioned(
          bottom: dialBottom,
          right: _fabMargin,
          child: _buildMainDialButton(),
        ),
      ],
    );
  }
}
