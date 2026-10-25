import 'dart:async';

import 'package:flutter/widgets.dart';

/// Keeps a local view current after writes, resuming the app, and midnight.
/// The owner loads its initial data and disposes this observer with the view.
class LocalDataObserver with WidgetsBindingObserver {
  LocalDataObserver({
    required VoidCallback onChanged,
    Iterable<Stream<void>> changes = const [],
    DateTime Function()? now,
  }) : _onChanged = onChanged,
       _now = now ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
    for (final stream in changes) {
      _subscriptions.add(stream.listen((_) => _notify()));
    }
    _scheduleMidnight();
  }

  final VoidCallback _onChanged;
  final DateTime Function() _now;
  final _subscriptions = <StreamSubscription<void>>[];
  Timer? _midnight;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) _onChanged();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = _now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(tomorrow.difference(now), () {
      _notify();
      if (!_disposed) _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleMidnight();
      _notify();
    } else {
      _midnight?.cancel();
    }
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}
