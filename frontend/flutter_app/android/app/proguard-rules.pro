# Proguard rules for Flutter app optimization and memory management

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep Hive classes (used for local storage)
-keep class hive.** { *; }
-keep class hive_flutter.** { *; }

# Keep WebRTC classes for audio/video
-keep class org.webrtc.** { *; }
-keep class com.cloudwebrtc.** { *; }

# Optimize memory by removing unused resources
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Preserve line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Preserve all annotations
-keepattributes *Annotation*

# Preserve generic signatures
-keepattributes Signature

# Audio processing optimizations
-keep class android.media.** { *; }
-keep class androidx.media.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Networking optimizations  
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Dart/Flutter interop
-keep class dart.** { *; }

# Memory optimization settings
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# Reduce APK size while preserving functionality
-repackageclasses ''
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose