import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader().use { reader ->
        localProperties.load(reader)
    }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionName = localProperties.getProperty("flutter.versionName")

android {
    namespace = "com.example.ar_memo_frontend"
    compileSdk = (localProperties.getProperty("flutter.compileSdkVersion") ?: "36").toInt()
    ndkVersion = localProperties.getProperty("flutter.ndkVersion") ?: "27.0.12077973"

    compileOptions {
        // ✅ Java 17로 통일
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // ✅ Kotlin JVM 타깃 17로 통일
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.ar_memo_frontend"
        minSdk = (localProperties.getProperty("flutter.minSdkVersion") ?: "24").toInt()
        targetSdk = (localProperties.getProperty("flutter.targetSdkVersion") ?: "36").toInt()
        versionCode = flutterVersionCode?.toInt() ?: 1
        versionName = flutterVersionName ?: "1.0"
        multiDexEnabled = true
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = "a04b18bad57c4a8b33e9eccada1f9748"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// ✅ Kotlin Toolchain으로도 17을 강제 (추가 안전장치)
kotlin {
    jvmToolchain(17)
}