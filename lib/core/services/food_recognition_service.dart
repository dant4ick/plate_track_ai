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
      debugPrint('FoodRecognitionService already initialized (ref count: $_referenceCount)');
    }
  }

  /// Recognize food nutrition values from an image
  /// Now the model outputs per 100g values for nutrition facts (except mass)
  Future<Map<String, double>> recognizeFoodValues(File imageFile) async {
    if (_nutritionInterpreter == null) {
      throw StateError('FoodRecognitionService not initialized. Call initialize() first.');
    }

    // 1. Preprocess image into a flat Float32List
    final flatInput = await _preprocessImage(imageFile); // length = 224*224*3

    // 2. Manually reshape into [1, 224, 224, 3]
    const int height = 224, width = 224, channels = 3;
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

    // 3. Prepare output buffer of shape [1, 5]
    final output = List.filled(5, 0.0).reshape([1, 5]);

    // 4. Run inference
    _nutritionInterpreter!.run(inputTensor, output);

    // 5. Return results
    final mass = output[0][1];
    
    // Return raw values per 100g now (except mass)
    // Total values will be calculated in UI based on actual mass
    return {
      'calories': output[0][0],  // calories per 100g
      'mass': mass,              // actual mass in grams
      'fat': output[0][2],       // fat per 100g
      'carbs': output[0][3],     // carbs per 100g
      'protein': output[0][4],   // protein per 100g
    };
  }

  /// Decode, crop, resize, and flatten the image into a Float32List
  Future<Float32List> _preprocessImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Failed to decode image');

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
    final resized = img.copyResize(cropped, width: 224, height: 224);

    final input = Float32List(224 * 224 * 3);
    int idx = 0;
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[idx++] = pixel.r.toDouble();
        input[idx++] = pixel.g.toDouble();
        input[idx++] = pixel.b.toDouble();
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
      debugPrint('FoodRecognitionService dispose called (ref count: $_referenceCount, keeping alive)');
    }
  }
}
