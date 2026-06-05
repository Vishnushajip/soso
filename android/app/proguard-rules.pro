# Flutter wrapper — keep embedding/engine entry points.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase / Google Play services keep rules (R8 generally handles these, but
# keep model classes & avoid warnings for reflective access).
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics: keep line numbers / source file for readable stack traces.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# google_sign_in / credentials.
-keep class com.google.android.gms.auth.** { *; }

# Keep annotations used by various plugins.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Some plugins rely on javax.annotation present at compile only.
-dontwarn javax.annotation.**
