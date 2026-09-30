import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

/// A service that recognizes food nutrition values from an image
/// by manually constructing a 4-D input tensor.
class FoodRecognitionService {
  static final FoodRecognitionService _instance =
      FoodRecognitionService._internal();

  factory FoodRecognitionService() => _instance;

  Interpreter? _nutritionInterpreter;
  bool _isInitialized = false;
  int _referenceCount = 0;

  FoodRecognitionService._internal();

  /// Initialize the TFLite interpreter
  Future<void> initialize() async {
    _referenceCount++;

    if (!_isInitialized) {
      _nutritionInterpreter = await Interpreter.fromAsset(
        'assets/ml/image2nutrition.tflite',
      );
      _isInitialized = true;
      debugPrint('FoodRecognitionService initialized');
    } else {
      debugPrint(
        'FoodRecognitionService already initialized (ref count: $_referenceCount)',
      );
    }
  }

  /// Recognize food nutrition values from an image
  /// Now the model outputs per 100g values for nutrition facts (except mass)
  Future<Map<String, double>> recognizeFoodValues(File imageFile) async {
    if (_nutritionInterpreter == null) {
      throw StateError(
        'FoodRecognitionService not initialized. Call initialize() first.',
      );
    }

    // 1. Preprocess image into a flat Float32List
    final flatInput = await _preprocessImage(imageFile); // length = 256*256*3

    // 2. Manually reshape into [1, 256, 256, 3]
    const int height = 256, width = 256, channels = 3;
    final inputTensor = <List<List<List<double>>>>[
      List.generate(height, (y) {
        return List.generate(width, (x) {
          final base = (y * width + x) * channels;
          return [
            flatInput[base + 0],
            flatInput[base + 1],
            flatInput[base + 2],
          ];
        });
      }),
    ];

    // Five separate float32 outputs, each with shape [1, 1].
    // Tensor order: mass, carbs, protein, calories, fat (see assets/ml/README.md).
    final outputBuffers = List.generate(
      5,
      (_) => <List<double>>[<double>[0.0]],
    );
    final outputs = <int, Object>{
      for (int i = 0; i < outputBuffers.length; i++) i: outputBuffers[i],
    };
    _nutritionInterpreter!.runForMultipleInputs([inputTensor], outputs);

    // Nutrition values are per 100 g; the UI calculates portion totals.
    return {
      'calories': outputBuffers[3][0][0],
      'mass': outputBuffers[0][0][0],
      'fat': outputBuffers[4][0][0],
      'carbs': outputBuffers[1][0][0],
      'protein': outputBuffers[2][0][0],
    };
  }

  /// Decode, crop, resize, and flatten the image into a Float32List
  Future<Float32List> _preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) throw Exception('Failed to decode image');

    // Respect EXIF orientation so crop/resize always run on upright pixels.
    final image = img.bakeOrientation(decoded);

    final width = image.width;
    final height = image.height;
    final cropSize = width < height ? width : height;
    final offsetX = (width - cropSize) ~/ 2;
    final offsetY = (height - cropSize) ~/ 2;

    final cropped = img.copyCrop(
      image,
      x: offsetX,
      y: offsetY,
      width: cropSize,
      height: cropSize,
    );
    final resized = img.copyResize(
      cropped,
      width: 256,
      height: 256,
      interpolation: img.Interpolation.cubic,
    );

    final input = Float32List(256 * 256 * 3);
    int idx = 0;
    for (int y = 0; y < 256; y++) {
      for (int x = 0; x < 256; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = pixel.r.toDouble() / 255.0;
        input[idx++] = pixel.g.toDouble() / 255.0;
        input[idx++] = pixel.b.toDouble() / 255.0;
      }
    }
    return input;
  }

  /// Dispose the interpreter when done
  void dispose() {
    _referenceCount--;

    if (_referenceCount <= 0) {
      _nutritionInterpreter?.close();
      _nutritionInterpreter = null;
      _isInitialized = false;
      _referenceCount = 0; // Ensure it doesn't go negative
      debugPrint('FoodRecognitionService disposed and interpreter closed');
    } else {
      debugPrint(
        'FoodRecognitionService dispose called (ref count: $_referenceCount, keeping alive)',
      );
    }
  }
}
