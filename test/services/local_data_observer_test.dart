import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_track_ai/core/services/local_data_observer.dart';

void main() {
  testWidgets('observes each source and stops after disposal', (tester) async {
    final foods = StreamController<void>.broadcast();
    final profiles = StreamController<void>.broadcast();
    var reloads = 0;
    final observer = LocalDataObserver(
      onChanged: () => reloads++,
      changes: [foods.stream, profiles.stream],
    );
    foods.add(null);
    profiles.add(null);
    await tester.pump();
    expect(reloads, 2);

    observer.dispose();
    foods.add(null);
    profiles.add(null);
    await tester.pump(const Duration(days: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(reloads, 2);
    await foods.close();
    await profiles.close();
  });

  testWidgets('updates at midnight and after returning from the background', (
    tester,
  ) async {
    var now = DateTime(2026, 12, 31, 23, 59, 59);
    var reloads = 0;
    final observer = LocalDataObserver(
      onChanged: () => reloads++,
      now: () => now,
    );
    addTearDown(observer.dispose);
    await tester.pump(const Duration(milliseconds: 999));
    expect(reloads, 0);
    now = DateTime(2027, 1, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(reloads, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2027, 1, 3, 18);
    await tester.pump(const Duration(days: 2, hours: 18));
    expect(reloads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(reloads, 2);

    now = DateTime(2027, 1, 4);
    await tester.pump(const Duration(hours: 6));
    expect(reloads, 3);
    observer.dispose();
  });
}
