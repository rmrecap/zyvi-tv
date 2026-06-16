# ──────────────────────────────────────────────
# Flutter/Dart model serialization
# ──────────────────────────────────────────────
-keep class lib.data.models.** { *; }
-keep class * extends hive.TypeAdapter { *; }

# ──────────────────────────────────────────────
# App Kotlin code (MethodChannel, PiP, etc.)
# ──────────────────────────────────────────────
-keep class com.example.zyvi_tv.** { *; }
-keepclassmembers class com.example.zyvi_tv.MainActivity { *; }

# ──────────────────────────────────────────────
# Firebase Firestore + Auth + Remote Config
# ──────────────────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*, EnclosingMethod, InnerClasses
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.firestore.DocumentSnapshot { *; }
-keep class com.google.firebase.firestore.QuerySnapshot { *; }
-keep class com.google.firebase.firestore.QueryDocumentSnapshot { *; }

# ──────────────────────────────────────────────
# Google Mobile Ads
# ──────────────────────────────────────────────
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# ──────────────────────────────────────────────
# BetterPlayer native layer
# ──────────────────────────────────────────────
-keep class com.betterplayer.** { *; }
-dontwarn com.betterplayer.**

# ──────────────────────────────────────────────
# AES / Crypto (PiP secure stream)
# ──────────────────────────────────────────────
-keep class javax.crypto.** { *; }
-keep class android.security.** { *; }

# ──────────────────────────────────────────────
# Flutter engine
# ──────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# ──────────────────────────────────────────────
# General — prevent R8 from stripping vital info
# ──────────────────────────────────────────────
-keepattributes SourceFile, LineNumberTable
-dontwarn javax.annotation.**
-dontwarn kotlin.**
