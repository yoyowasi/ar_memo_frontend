// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ar_memo_frontend"

    // Flutter Gradle plugin exposes these values directly for Kotlin DSL
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.ar_memo_frontend"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        release {
            // 필요 시 R8/ProGuard 설정 추가
            isMinifyEnabled = false
        }
        debug {
            isDebuggable = true
        }
    }

    // (필요 시) packagingOptions, signingConfigs 등은 프로젝트에 맞게 추가
}

dependencies {
    // Flutter가 관리하는 의존성이므로 일반적으로 별도 추가 불필요
}
