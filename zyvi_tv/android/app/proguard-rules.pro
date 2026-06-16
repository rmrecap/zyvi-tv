# Hive TypeAdapters - prevent obfuscation
-keep class com.example.zyvi_tv.** { *; }
-keep class * extends com.example.zyvi_tv.data.models.ChannelModel { *; }
-keep class * extends com.example.zyvi_tv.data.models.StreamSource { *; }

# BetterPlayer
-keep class com. betterplayer.** { *; }
-dontwarn com.betterplayer.**

# Firebase
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Keep Hive model classes
-keep class * implements com.hive.** { *; }

# AES / Crypto
-keep class javax.crypto.** { *; }
-keep class android.security.** { *; }

# Flutter engine
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
