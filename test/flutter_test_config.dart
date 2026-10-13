import 'dart:async';

import 'package:google_fonts/google_fonts.dart';
import 'package:plate_track_ai/core/themes/app_theme.dart';

/// Applies to every test under `test/`.
///
/// `AppTheme` builds its text themes with `GoogleFonts.poppinsTextTheme`, which
/// reaches for the font the first time a theme is constructed. Tests have no
/// network and the font is not bundled as an asset, so that first construction
/// throws asynchronously — landing on whichever test happens to touch a theme
/// first, and failing it for reasons that have nothing to do with the theme.
///
/// Runtime fetching is turned off so no test opens a socket, then the three
/// themes are built once here inside a guarded zone. That absorbs the one-time
/// failure; google_fonts caches the attempt, so later builds are silent and
/// fall back to the default font.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;

  final warmed = Completer<void>();
  runZonedGuarded(
    () async {
      final themes = [
        AppTheme.lightTheme,
        AppTheme.darkTheme,
        AppTheme.pickMeTheme,
      ];
      assert(themes.length == 3);
      await Future<void>.delayed(Duration.zero);
      if (!warmed.isCompleted) warmed.complete();
    },
    (_, _) {
      if (!warmed.isCompleted) warmed.complete();
    },
  );
  await warmed.future;

  await testMain();
}
