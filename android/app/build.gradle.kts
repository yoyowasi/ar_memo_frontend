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

android {
    namespace = "com.example.ar_memo_frontend"
    // 🟢 [수정] 로그의 추천대로 36으로 설정
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
        // 🟢 [수정] compileSdk와 동일하게 36으로 설정
        targetSdk = (localProperties.getProperty("flutter.targetSdkVersion") ?: "36").toInt()
        versionCode = flutterVersionCode?.toInt() ?: 1
        // 🟢 [수정] 이전의 줄바꿈 오류 수정
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
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
// ✅ Kotlin Toolchain으로도 17을 강제 (추가 안전장치)
kotlin {
    jvmToolchain(17)
}
dependencies {
    // ✅ EXIF 읽기를 위한 네이티브 의존성 추가
    implementation("androidx.exifinterface:exifinterface:1.4.1")
}