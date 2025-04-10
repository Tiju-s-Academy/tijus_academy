plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tijus_academy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tijus_academy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 33
        versionCode = flutter.versionCode.toInt()
        versionName = flutter.versionName.toString()
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Keep rules for Google Play Core library
            val keepRules = listOf(
                "-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication",
                "-dontwarn com.google.android.play.core.splitinstall.SplitInstallException",
                "-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager",
                "-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory",
                "-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest\$Builder",
                "-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest",
                "-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState",
                "-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener",
                "-dontwarn com.google.android.play.core.tasks.OnFailureListener",
                "-dontwarn com.google.android.play.core.tasks.OnSuccessListener",
                "-dontwarn com.google.android.play.core.tasks.Task",
            )
            keepRules.forEach {
                 proguardFile.writeText(it + "\\n")
            }
        }
    }
}

flutter {
    source = "../.."
}
