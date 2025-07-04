# Flutter & Dart
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Flutter Local Notifications Plugin
-keep class com.dexterous.** { *; }

# Keep native methods
-keepclasseswithmembers class * {
    native <methods>;
} 