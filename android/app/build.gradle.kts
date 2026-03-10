import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localEnv: Map<String, String> = run {
    val envFileCandidates = listOf(
        rootProject.file("../.env"), // repo root when Gradle root is /android
        rootProject.file(".env"),
    )
    val envFile = envFileCandidates.firstOrNull { it.exists() }
    if (envFile == null) {
        emptyMap()
    } else {
        val properties = Properties()
        envFile.inputStream().use { properties.load(it) }
        properties.stringPropertyNames().associateWith {
            properties.getProperty(it).trim()
        }
    }
}

fun resolveEnvValue(key: String): String? {
    val gradleProperty = providers.gradleProperty(key).orNull
    if (!gradleProperty.isNullOrBlank()) {
        return gradleProperty
    }

    val systemEnv = System.getenv(key)
    if (!systemEnv.isNullOrBlank()) {
        return systemEnv
    }

    val envFileValue = localEnv[key]
    if (!envFileValue.isNullOrBlank()) {
        return envFileValue
    }

    return null
}

android {
    namespace = "com.eirenya.quiznetic"
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.eirenya.quiznetic"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["ADMOB_APP_ID"] =
            resolveEnvValue("ADS_ANDROID_APP_ID") ?: ""
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
