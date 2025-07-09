plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.emacsah.taxasge"
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
    }
    
    defaultConfig {
        applicationId = "com.emacsah.taxasge"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Syntaxe correcte pour Kotlin DSL
//configurations.all {
//    resolutionStrategy {
//        force("com.google.android.gms:play-services-measurement-api:21.5.0")
//        force("com.google.android.gms:play-services-measurement-impl:21.5.0")
//    }
//}