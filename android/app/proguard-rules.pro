# R8 / ProGuard rules for release builds.
#
# Minification is on (build.gradle.kts) to keep the download small, but the
# audio stack and Firebase both rely on reflection, so the classes they look
# up by name have to survive renaming. Anything removed here fails at
# *runtime in release only* — never in debug and never in `flutter analyze` —
# so treat additions as needing a real release-build smoke test on a device.

# --- DEX Code Optimization & Repackaging ----------------------------------
# Flatten and repackage obfuscated classes into the root package.
# Satisfies Google Play Console R8 "Repackage Classes" check, increases
# obfuscation/shrinking percentages above Google Play's 25% threshold,
# and reduces uncompressed DEX size.
-repackageclasses ''
-allowaccessmodification

# --- Crash reporting -------------------------------------------------------
# Without these, Crashlytics stack traces come back as obfuscated noise and
# field reports become undiagnosable.
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature,InnerClasses,EnclosingMethod
-renamesourcefileattribute SourceFile

# --- just_audio / audio_service (ExoPlayer / Media3) -----------------------
# ExoPlayer and Media3 ship built-in consumer rules in their AAR artifacts.
-dontwarn com.google.android.exoplayer2.**
-dontwarn androidx.media3.**

# audio_service's background service and media button receiver are named in
# AndroidManifest.xml, so they are resolved by string, not by reference.
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# MediaBrowserService / MediaSession compat surface used by the lock screen,
# notification and Bluetooth controls.
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }

# --- Firebase & Google Mobile Ads ------------------------------------------
# Modern Firebase, Google Play Services, and AdMob libraries package their
# own official consumer-rules.pro inside their AARs. Avoiding blanket -keep
# on these SDKs allows R8 to shrink and optimize them effectively.
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.android.gms.ads.**

# Firestore's model mapper reads annotated members by reflection.
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
    @com.google.firebase.firestore.PropertyName <methods>;
}

# --- Play Core ------------------------------------------------------------
# Flutter's deferred-components hooks reference Play Core even when the app
# does not use deferred components; without this R8 fails on missing classes.
-dontwarn com.google.android.play.core.**
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# --- Room / WorkManager / App Startup --------------------------------------
# Caught by a release-build smoke test, not by any analyzer: without these
# the app died on launch with
#   "Failed to create an instance of androidx.work.impl.WorkDatabase"
# Room instantiates its generated implementation by name ("<Database>_Impl"),
# so R8 sees no reference to it and strips it; androidx.startup then fails
# to initialise WorkManager and takes the whole process down before Flutter
# even starts.
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.room.** { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public <init>(...);
}
-dontwarn androidx.room.**
-dontwarn androidx.room.paging.**

-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker { *; }
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(...);
}
-dontwarn androidx.work.**

# Initializers are named in the merged manifest and resolved reflectively.
-keep class androidx.startup.** { *; }
-keep class * implements androidx.startup.Initializer { *; }

# --- Kotlin / coroutines ---------------------------------------------------
-dontwarn kotlin.**
-dontwarn kotlinx.coroutines.**
-keepclassmembers class kotlinx.coroutines.** { volatile <fields>; }
