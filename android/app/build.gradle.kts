import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

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
    namespace = "com.hoque.familychores"
    // Google Play requires apps to target Android 16 (API 36). Flutter 3.32.5's
    // default (flutter.compileSdkVersion/targetSdkVersion) is below 36, so we
    // pin both explicitly. AGP 8.7.0 + the installed android-36 platform support
    // this without a Flutter upgrade.
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // flutter_local_notifications 17+ uses java.time APIs that aren't on
        // older Android; desugaring back-ports them. Without this the release
        // build fails checkReleaseAarMetadata. See #129.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hoque.familychores" // Keep your existing applicationId
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // firebase-auth 23.x requires API 23+; Flutter's default (21) fails the
        // manifest merge. 23 (Android 6.0, 2015) is a fine floor for a family
        // app. See #129.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = 36 // Google Play requirement: target Android 16 (API 36)
        versionCode = flutter.versionCode      // Keep this as is
        versionName = flutter.versionName      // Keep this as is
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            // You need to add the following line to the release section.
            // It tells Gradle to use the signing configuration you just defined.
            signingConfig = signingConfigs.getByName("release")
            // Other existing settings like isMinifyEnabled or proguardFiles might be here.
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Back-ports java.time (and friends) that flutter_local_notifications 17+
    // relies on, so the app runs on older Android. Required by the desugaring
    // flag above. See #129.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
