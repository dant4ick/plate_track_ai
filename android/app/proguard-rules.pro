# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep model files
-keep class * extends org.tensorflow.lite.Interpreter { *; }

# Additional required rules for TFLite
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.**