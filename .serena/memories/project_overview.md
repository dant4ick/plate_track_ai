# Plate Track AI - Project Overview

## Purpose
A Flutter mobile app for tracking food nutrition using AI image recognition. Users can photograph food, get nutritional analysis via TFLite models, and track their daily intake.

## Tech Stack
- **Framework**: Flutter (Dart SDK ^3.7.2)
- **State Management**: Provider
- **Storage**: Hive (local), SharedPreferences
- **AI/ML**: TFLite Flutter
- **Camera**: camera package + image_picker
- **UI**: Material Design, google_fonts, fl_chart, shimmer, cached_network_image, flutter_svg
- **Localization**: easy_localization (en, ru)
- **Models**: Equatable, UUID

## Codebase Structure
```
lib/
├── main.dart                     # App entry, Hive init, navigation (HomeScreen with bottom nav)
├── core/
│   ├── services/
│   │   ├── food_data_provider.dart    # Empty file
│   │   ├── food_recognition_service.dart  # TFLite-based food recognition
│   │   ├── food_storage_service.dart      # Hive-based storage
│   │   └── user_profile_service.dart
│   └── themes/app_theme.dart
├── features/
│   ├── dashboard/dashboard_screen.dart
│   ├── food_recognition/
│   │   ├── food_camera_screen.dart          # Camera + gallery image capture
│   │   └── recognition_result_screen.dart   # Edit & save recognized food
│   ├── nutrition_stats/
│   ├── profile/
│   ├── recommendations/
│   └── user_setup/
└── shared/
    ├── models/
    │   ├── food_item.dart              # FoodItem + NutritionFacts (Hive models)
    │   ├── food_item_adapters.dart
    │   ├── user_profile.dart
    │   └── user_profile_adapters.dart
    └── widgets/
        ├── app_logo.dart
        ├── common_widgets.dart         # AppButton, LoadingIndicator, FrameGuideline, etc.
        ├── delete_food.dart
        ├── food_items.dart
        └── standard_app_bar.dart
```

## Navigation
- HomeScreen has bottom nav with 5 items: Home, Stats, **Camera (main button)**, Recommendations, Profile
- Camera button navigates to FoodCameraScreen via `Navigator.push`
- FoodCameraScreen → RecognitionResultScreen → pop back to HomeScreen on save

## Key Patterns
- Services are singletons (factory constructors with _internal)
- Localization via `'key'.tr()` from easy_localization
- Nutrition values stored as per-100g; mass stored separately
- Common widgets in shared/widgets/common_widgets.dart (AppButton, LoadingIndicator, etc.)
