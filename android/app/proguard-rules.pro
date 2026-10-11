# Proguard rules for Tabib

# Flutter deferred components & Play Core warnings suppression
-dontwarn com.google.android.play.core.**

# Flutter and JNI / fllama keep rules
-keep class io.flutter.** { *; }
-keep class ink.xcl.fllama.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
