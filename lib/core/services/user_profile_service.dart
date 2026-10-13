import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plate_track_ai/core/services/weight_history_service.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class UserProfileService {
  static const String _userProfileBoxName = 'userProfile';
  static const String _currentUserIdKey = 'currentUserId';
  
  Box<UserProfile>? _userProfileBox;
  final WeightHistoryService _weightHistory = WeightHistoryService();
  UserProfile? _currentProfile;

  Future<void> initialize() async {
    try {
      _userProfileBox = await Hive.openBox<UserProfile>(_userProfileBoxName);
      await _loadCurrentProfile();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserProfileService: Error initializing service: $e');
      }
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString(_currentUserIdKey);
      
      if (currentUserId != null && _userProfileBox != null) {
        _currentProfile = _userProfileBox!.get(currentUserId);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('UserProfileService: Error loading current profile: $e');
      }
    }
  }

  UserProfile? get currentProfile => _currentProfile;

  bool get hasUserProfile => _currentProfile != null;

  Future<UserProfile> createProfile({
    required int age,
    required double weight,
    required double height,
    required Gender gender,
    required ActivityLevel activityLevel,
    double? goalWeight,
  }) async {
    if (_userProfileBox == null) {
      throw Exception('UserProfileService not initialized');
    }

    final profile = UserProfile(
      id: const Uuid().v4(),
      age: age,
      weight: weight,
      height: height,
      gender: gender,
      activityLevel: activityLevel,
      createdAt: DateTime.now(),
      // Today's weight is the baseline every future goal is measured against.
      startWeight: weight,
      goalWeight: goalWeight,
    );

    await _userProfileBox!.put(profile.id, profile);
    // The first point on the weight chart is the weight the profile opened with.
    await _weightHistory.record(weight, at: profile.createdAt);
    
    // Set as current profile
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, profile.id);
    
    _currentProfile = profile;
    return profile;
  }

  Future<UserProfile> updateProfile({
    int? age,
    double? weight,
    double? height,
    Gender? gender,
    ActivityLevel? activityLevel,
    double? startWeight,
    double? goalWeight,
    bool clearGoalWeight = false,
  }) async {
    if (_currentProfile == null || _userProfileBox == null) {
      throw Exception('No current profile to update');
    }

    final updatedProfile = _currentProfile!.copyWith(
      age: age,
      weight: weight,
      height: height,
      gender: gender,
      activityLevel: activityLevel,
      updatedAt: DateTime.now(),
      // A profile that predates goal tracking has no baseline. The first update
      // after upgrading backfills one from the weight the profile held *before*
      // this edit — using the incoming weight instead would set the baseline to
      // the new value and permanently report zero progress.
      startWeight:
          startWeight ??
          _currentProfile!.startWeight ??
          _currentProfile!.weight,
      goalWeight: goalWeight,
      clearGoalWeight: clearGoalWeight,
    );

    await _userProfileBox!.put(updatedProfile.id, updatedProfile);
    if (weight != null) {
      await _weightHistory.record(weight);
    }
    _currentProfile = updatedProfile;
    
    return updatedProfile;
  }

  Future<void> deleteProfile() async {
    if (_currentProfile == null || _userProfileBox == null) {
      return;
    }

    await _userProfileBox!.delete(_currentProfile!.id);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);
    
    _currentProfile = null;
  }

  // Calculate user's daily calorie needs based on current profile
  double? calculateDailyCalorieNeeds() {
    if (_currentProfile == null) {
      return null;
    }
    return _currentProfile!.calculateTDEE();
  }

  // Calculate user's BMR based on current profile
  double? calculateBMR() {
    if (_currentProfile == null) {
      return null;
    }
    return _currentProfile!.calculateBMR();
  }

  // Get basic nutrition targets based on TDEE
  Map<String, double>? getNutritionTargets() {
    final tdee = calculateDailyCalorieNeeds();
    if (tdee == null) {
      return null;
    }

    // Standard macro distribution:
    // Protein: 10-35% of total calories (using 20%)
    // Carbs: 45-65% of total calories (using 50%)
    // Fat: 20-35% of total calories (using 30%)
    
    return {
      'calories': tdee,
      'protein': (tdee * 0.20) / 4, // 4 calories per gram of protein
      'carbs': (tdee * 0.50) / 4, // 4 calories per gram of carbs
      'fat': (tdee * 0.30) / 9, // 9 calories per gram of fat
    };
  }

  void dispose() {
    _userProfileBox?.close();
  }
}
