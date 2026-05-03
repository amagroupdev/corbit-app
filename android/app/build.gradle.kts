import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "sa.corbit.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            val envKeyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: keystoreProperties["keyAlias"] as String?
            val envKeyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: keystoreProperties["keyPassword"] as String?
            val envStorePath = System.getenv("ANDROID_KEYSTORE_PATH") ?: keystoreProperties["storeFile"] as String?
            val envStorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: keystoreProperties["storePassword"] as String?
            if (envKeyAlias != null) keyAlias = envKeyAlias
            if (envKeyPassword != null) keyPassword = envKeyPassword
            if (envStorePath != null) storeFile = file(envStorePath)
            if (envStorePassword != null) storePassword = envStorePassword
        }
    }

    defaultConfig {
        applicationId = "sa.corbit.app"
        minSdk = flutter.minSdkVersion
        multiDexEnabled = true
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use debug signing for direct-download APK distribution (no Play Store)
            // Original release signingConfig retained above for future use when keystore is available
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
