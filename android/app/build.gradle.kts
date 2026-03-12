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
        fun parseEnvValue(rawValue: String, lineNumber: Int): String {
            if (rawValue.isEmpty()) {
                return ""
            }

            val startsWithDoubleQuote = rawValue.startsWith("\"")
            val endsWithDoubleQuote = rawValue.endsWith("\"")
            val startsWithSingleQuote = rawValue.startsWith("'")
            val endsWithSingleQuote = rawValue.endsWith("'")
            if (startsWithDoubleQuote || endsWithDoubleQuote) {
                if (
                    !startsWithDoubleQuote ||
                        !endsWithDoubleQuote ||
                        rawValue.length < 2
                ) {
                    throw GradleException(
                        "Invalid env line $lineNumber in ${envFile.path}: unmatched double quote",
                    )
                }
                return rawValue.substring(1, rawValue.length - 1)
            }
            if (startsWithSingleQuote || endsWithSingleQuote) {
                if (
                    !startsWithSingleQuote ||
                        !endsWithSingleQuote ||
                        rawValue.length < 2
                ) {
                    throw GradleException(
                        "Invalid env line $lineNumber in ${envFile.path}: unmatched single quote",
                    )
                }
                return rawValue.substring(1, rawValue.length - 1)
            }
            return rawValue
        }

        buildMap {
            envFile.useLines { lines ->
                lines.forEachIndexed { index, rawLine ->
                    val lineNumber = index + 1
                    val trimmedLine = rawLine.removeSuffix("\r").trim()
                    if (trimmedLine.isEmpty() || trimmedLine.startsWith("#")) {
                        return@forEachIndexed
                    }

                    val normalizedLine = if (trimmedLine.startsWith("export ")) {
                        trimmedLine.removePrefix("export").trimStart()
                    } else {
                        trimmedLine
                    }

                    val separatorIndex = normalizedLine.indexOf('=')
                    if (separatorIndex <= 0) {
                        throw GradleException(
                            "Invalid env line $lineNumber in ${envFile.path}: expected KEY=VALUE",
                        )
                    }

                    val key = normalizedLine.substring(0, separatorIndex).trim()
                    if (!key.matches(Regex("[A-Za-z_][A-Za-z0-9_]*"))) {
                        throw GradleException(
                            "Invalid env line $lineNumber in ${envFile.path}: invalid key \"$key\"",
                        )
                    }

                    val rawValue = normalizedLine.substring(separatorIndex + 1).trim()
                    put(key, parseEnvValue(rawValue, lineNumber))
                }
            }
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
