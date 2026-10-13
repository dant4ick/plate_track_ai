import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/shared/models/user_profile.dart';

import '../test_utils.dart';

void main() {
  group('UserProfile.minimumHealthyWeight', () {
    test('is the weight at BMI 18.5 for the given height', () {
      // 1.70 m squared is 2.89 m²; 18.5 × 2.89 = 53.465 kg.
      expect(UserProfile.minimumHealthyWeight(170), closeTo(53.465, 1e-6));
    });

    test('scales with the square of height', () {
      expect(
        UserProfile.minimumHealthyWeight(200),
        closeTo(UserProfile.minimumHealthyWeight(100) * 4, 1e-6),
      );
    });

    test('the instance getter reads the profile height', () {
      final profile = TestDataFactory.createUserProfile(height: 180);
      expect(profile.minimumGoalWeight, closeTo(18.5 * 1.8 * 1.8, 1e-6));
    });

    test('bmi divides weight by height squared', () {
      final profile = TestDataFactory.createUserProfile(weight: 72.25, height: 170);
      expect(profile.bmi, closeTo(25.0, 1e-6));
    });
  });
}
