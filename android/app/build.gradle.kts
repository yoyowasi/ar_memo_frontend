// **** 맨 위에 필요한 import 문을 추가합니다 ****
import java.util.Properties
import groovy.lang.GroovyObject

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// flutter 객체를 사용하기 전에 local.properties를 로드하는 로직은
// 최상위 android/build.gradle.kts 또는 android/settings.gradle.kts에 있어야 합니다.
// 이 파일(app/build.gradle.kts)에는 필요하지 않습니다.
// (기존 yoyowasi 프로젝트 파일 기준으로 복원합니다.)

// 'flutter' 객체는 'id("dev.flutter.flutter-gradle-plugin")' 플러그인에 의해 자동으로 주입됩니다.
val flutter = extensions.getByName("flutter") as GroovyObject

android {
    namespace = "com.example.ar_memo_frontend"
    compileSdk = (flutter.getProperty("compileSdkVersion") as Int)
    ndkVersion = flutter.getProperty("ndkVersion") as String

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8 // AR 플러그인 요구사항
        targetCompatibility = JavaVersion.VERSION_1_8 // AR 플러그인 요구사항
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8.toString() // AR 플러그인 요구사항
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.ar_memo_frontend"
        // AR 플러그인 요구사항 (24 이상)
        minSdk = 24
        targetSdk = (flutter.getProperty("targetSdkVersion") as Int)
        versionCode = (flutter.getProperty("versionCode")?.toString()?.toIntOrNull() ?: 1)
        versionName = flutter.getProperty("versionName") as String
        multiDexEnabled = true // MultiDex 활성화
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // --- ARCore 설정 (경고 수정된 버전) ---
    packaging { // 'packagingOptions' 대신 'packaging' 사용
        jniLibs { // '.so' 파일은 jniLibs
            pickFirsts += listOf(
                "lib/arm64-v8a/libarcore_sdk_jni.so",
                "lib/armeabi-v7a/libarcore_sdk_jni.so",
                "lib/x86/libarcore_sdk_jni.so",
                "lib/x86_64/libarcore_sdk_jni.so"
            )
        }
    }
    // ---------------------------------
}

flutter {
    source = "../.."
}

dependencies {
    // ARCore 의존성 추가
    implementation("com.google.ar:core:1.33.0") // ARCore SDK 버전
    // MultiDex 의존성 추가
    implementation("androidx.multidex:multidex:2.0.1")
    // Kotlin 표준 라이브러리 (필수)
    // 'kotlin-android' 플러그인이 버전에 맞는 라이브러리를 자동으로 추가해주는 경우가 많지만,
    // 명시적으로 추가합니다. (버전은 프로젝트 설정에 맞게 조정 필요)
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.8.22")
}
