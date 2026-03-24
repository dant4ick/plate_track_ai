import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:plate_track_ai/shared/models/cached_barcode_product.dart';

class BarcodeCacheService {
  static final BarcodeCacheService _instance = BarcodeCacheService._internal();
  factory BarcodeCacheService() => _instance;
  BarcodeCacheService._internal();

  static const String _boxName = 'barcode_cache';
  Box<CachedBarcodeProduct>? _box;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<CachedBarcodeProduct>(_boxName);
    _isInitialized = true;
  }

  Box<CachedBarcodeProduct> get _safeBox {
    if (_box == null || !_isInitialized) {
      throw StateError('BarcodeCacheService not initialized. Call initialize() first.');
    }
    return _box!;
  }

  CachedBarcodeProduct? lookup(String barcode) {
    try {
      return _safeBox.get(barcode);
    } catch (e) {
      if (kDebugMode) debugPrint('BarcodeCacheService: lookup error: $e');
      return null;
    }
  }

  Future<void> save(CachedBarcodeProduct product) async {
    try {
      await _safeBox.put(product.barcode, product);
    } catch (e) {
      if (kDebugMode) debugPrint('BarcodeCacheService: save error: $e');
    }
  }

  Future<void> delete(String barcode) async {
    try {
      await _safeBox.delete(barcode);
    } catch (e) {
      if (kDebugMode) debugPrint('BarcodeCacheService: delete error: $e');
    }
  }

  List<CachedBarcodeProduct> getAll() {
    try {
      return _safeBox.values.toList();
    } catch (e) {
      if (kDebugMode) debugPrint('BarcodeCacheService: getAll error: $e');
      return [];
    }
  }
}
