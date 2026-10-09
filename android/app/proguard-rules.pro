# Keep Generic Signatures and Annotations for Reflection & Gson TypeToken
# CRITICAL: Without these, Gson throws "Missing type parameter" on release builds!
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Gson library rules
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }
-keepclassmembers class * implements com.google.gson.TypeAdapter { *; }
-keepclassmembers class * implements com.google.gson.TypeAdapterFactory { *; }
-keepclassmembers class * implements com.google.gson.JsonSerializer { *; }
-keepclassmembers class * implements com.google.gson.JsonDeserializer { *; }
-dontwarn com.google.gson.**

# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keepclassmembers class com.dexterous.** { *; }
-dontwarn com.dexterous.**
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.models.** { *; }

# Isar Database
-keep class dev.isar.** { *; }
-keepclassmembers class dev.isar.** { *; }
-dontwarn dev.isar.**

# Just Audio
-keep class com.ryanheise.just_audio.** { *; }
-keepclassmembers class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**
