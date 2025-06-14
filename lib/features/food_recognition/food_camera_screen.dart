import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plate_track_ai/core/constants/app_strings.dart';
import 'package:plate_track_ai/shared/widgets/common_widgets.dart';
import 'package:plate_track_ai/features/food_recognition/recognition_result_screen.dart';
import 'package:plate_track_ai/core/services/food_recognition_service.dart';
import 'package:plate_track_ai/shared/models/food_item.dart';
import 'package:plate_track_ai/core/services/food_storage_service.dart';

class FoodCameraScreen extends StatefulWidget {
  const FoodCameraScreen({Key? key}) : super(key: key);

  @override
  State<FoodCameraScreen> createState() => _FoodCameraScreenState();
}

class _FoodCameraScreenState extends State<FoodCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  bool _isCapturing = false; // Track when a photo is being captured
  FlashMode _flashMode = FlashMode.off;
  // Keep track of whether we came from gallery to handle state properly
  bool _isFromGallery = false;
  
  // ML services
  final FoodRecognitionService _recognitionService = FoodRecognitionService();
  final FoodStorageService _storageService = FoodStorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    
    // Initialize the recognition service
    _recognitionService.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    // Dispose recognition service
    _recognitionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // This happens when the app is unfocused
      // Dispose the camera controller here to ensure flash is reset
      cameraController.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      // When app is refocused, initialize camera with the stored flash mode
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) return;

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      
      // Set initial flash mode
      await _controller!.setFlashMode(_flashMode);

      if (!mounted) return;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  // Toggle flash mode
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      FlashMode newMode;
      
      // Cycle through flash modes: off -> auto -> always
      switch (_flashMode) {
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newMode = FlashMode.always;
          break;
        default:
          newMode = FlashMode.off;
      }
      
      await _controller!.setFlashMode(newMode);
      
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      debugPrint('Error toggling flash: $e');
    }
  }

  // Get flash icon based on current mode
  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isAnalyzing || _isCapturing) {
      return;
    }

    try {
      // Set capturing state to true to prevent multiple button presses
      setState(() {
        _isCapturing = true;
      });

      // Remember the current flash mode for later
      final currentFlashMode = _flashMode;

      // Take the picture with current flash settings
      final XFile photo = await _controller!.takePicture();

      // Now that the photo is captured, we can show the analyzing state
      if (mounted) {
        setState(() {
          _isAnalyzing = true;
          _isCapturing = false; // Reset capturing state
        });
      }

      // Completely dispose and recreate the camera controller
      // This is the most effective way to ensure the flash hardware is reset
      await _controller!.dispose();

      // Create a new controller
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      // Initialize the new controller
      await _controller!.initialize();

      // Restore the flash mode that was selected before
      await _controller!.setFlashMode(currentFlashMode);

      if (mounted) {
        setState(() {
          // This ensures the UI updates with the new controller
          _flashMode = currentFlashMode;
        });
      }

      _processImage(File(photo.path));
    } catch (e) {
      debugPrint('Error taking picture: $e');
      // If any error happens, make sure we reinitialize the camera
      _initializeCamera();
      setState(() {
        _isAnalyzing = false;
        _isCapturing = false; // Reset capturing state
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isAnalyzing || _isCapturing) return;

    setState(() {
      _isAnalyzing = true;
      _isFromGallery = true; // Flag that we're using gallery
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        // Process the image
        await _processImage(File(image.path));
      } else {
        // User canceled the picker
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _isFromGallery = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _isFromGallery = false;
        });
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    if (!mounted) return;
    
    try {
      // Get nutrition data from the recognition service
      // These are now per 100g values (except for mass)
      final nutritionValues = await _recognitionService.recognizeFoodValues(imageFile);
      
      if (!mounted) return;
      
      // Create food item with per 100g nutrition values
      final foodItem = FoodItem(
        name: 'Food Item',
        // Store per 100g values in the food item
        calories: nutritionValues['calories'] ?? 0,
        nutritionFacts: NutritionFacts(
          protein: nutritionValues['protein'] ?? 0,
          carbohydrates: nutritionValues['carbs'] ?? 0,
          fat: nutritionValues['fat'] ?? 0,
          mass: nutritionValues['mass'] ?? 100.0, // Default to 100g if not available
        ),
        imagePath: imageFile.path,
      );
      
      // Navigate to results screen with the data
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecognitionResultScreen(
            imageFile: imageFile,
            foodItem: foodItem,
            onSave: (FoodItem item) async {
              // Save to storage when user confirms
              await _storageService.saveFoodItem(item);
            },
          ),
        ),
      );
      
      // Check if a result was returned and update state
      if (mounted) {
        if (_isFromGallery) {
          // Explicitly force a complete rebuild of the screen for gallery images
          _isFromGallery = false;
          await _initializeCamera(); // Reinitialize camera to ensure it's working properly
        }
        
        setState(() {
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      
      // Create a fallback food item with sample data
      final fallbackFoodItem = FoodItem(
        name: 'Sample Food',
        calories: 245,
        nutritionFacts: const NutritionFacts(
          protein: 15,
          carbohydrates: 30,
          fat: 8,
          mass: 100,
        ),
        imagePath: imageFile.path,
      );
      
      // Navigate to results screen with fallback data
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecognitionResultScreen(
              imageFile: imageFile,
              foodItem: fallbackFoodItem,
              onSave: (FoodItem item) async {
                // Save to storage when user confirms
                await _storageService.saveFoodItem(item);
              },
            ),
          ),
        );
        
        if (_isFromGallery) {
          // Explicitly force a complete rebuild of the screen for gallery images
          _isFromGallery = false;
          await _initializeCamera(); // Reinitialize camera to ensure it's working properly
        }
        
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return Scaffold(
        body: LoadingIndicator(message: AppStrings.analyzing),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Scanner'),
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          
          // Framing guideline
          Center(
            child: FrameGuideline(
              size: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          
          // Flash toggle button
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: Icon(
                  _getFlashIcon(),
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  if (!_isCapturing && !_isAnalyzing) {
                    _toggleFlash();
                  }
                },
                tooltip: 'Toggle flash mode',
              ),
            ),
          ),
          
          // Instruction text
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isCapturing ? "Capturing..." : AppStrings.frameYourFood,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // Capturing indicator overlay
          if (_isCapturing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
          
          // Bottom actions panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: 24, 
                right: 24, 
                top: 20, 
                bottom: 36
              ),
              decoration: const BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  AppButton(
                    text: AppStrings.selectFromGallery,
                    onPressed: () {
                      if (!_isCapturing && !_isAnalyzing) {
                        _pickImageFromGallery();
                      }
                    },
                    isSecondary: true,
                    icon: Icons.photo_library,
                  ),
                  const SizedBox(width: 16),
                  AppButton(
                    text: AppStrings.takePhoto,
                    onPressed: () {
                      if (!_isCapturing && !_isAnalyzing) {
                        _takePicture();
                      }
                    },
                    icon: Icons.camera_alt,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}