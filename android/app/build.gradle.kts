// android/app/build.gradle.kts

import java.io.FileInputStream
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

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode")
val flutterVersionName = localProperties.getProperty("flutter.versionName")

// 🟢 카카오 네이티브 앱 키 로드
val kakaoNativeAppKey = localProperties.getProperty("KAKAO_MAP_NATIVE_APP_KEY") ?: ""

android {
    namespace = "com.example.ar_memo_frontend"
    compileSdk = (localProperties.getProperty("flutter.compileSdkVersion") ?: "36").toInt()
    ndkVersion = localProperties.getProperty("flutter.ndkVersion") ?: "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    signingConfigs {
        create("release") {
            if (keyPropertiesFile.exists()) {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.example.ar_memo_frontend"
        minSdk = (localProperties.getProperty("flutter.minSdkVersion") ?: "24").toInt()
        targetSdk = (localProperties.getProperty("flutter.targetSdkVersion") ?: "36").toInt()
        versionCode = flutterVersionCode?.toInt() ?: 1
        versionName = flutterVersionName ?: "1.0"

        multiDexEnabled = true

        // 🟢 local.properties에서 로드한 키 사용
        manifestPlaceholders["KAKAO_MAP_NATIVE_APP_KEY"] = kakaoNativeAppKey
        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = kakaoNativeAppKey
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    jvmToolchain(17)
}

dependencies {
    implementation("androidx.exifinterface:exifinterface:1.4.1")
}
