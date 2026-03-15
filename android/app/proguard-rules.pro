# Flutter Shrinkage Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Fix for R8 "Missing classes" errors
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.internal.**
-dontwarn com.google.android.gms.common.**
-dontwarn javax.annotation.**
