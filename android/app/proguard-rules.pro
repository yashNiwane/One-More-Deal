# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Postgres JDBC driver - keep all classes to prevent R8 stripping
-keep class org.postgresql.** { *; }
-keep class com.ongres.** { *; }

# Keep all classes that use reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }

# Razorpay
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keep class com.razorpay.** { *; }
-keep public class com.razorpay.*
-dontwarn com.razorpay.**

# Suppress warnings
-dontwarn org.postgresql.**
-dontwarn com.ongres.**

# Fix R8 missing classes: Google Play Core (split install) — not needed for APK distribution
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

