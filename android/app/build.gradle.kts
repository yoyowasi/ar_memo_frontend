// android/app/build.gradle.kts (module-level)

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// ✅ Kotlin DSL에서 flutter 확장을 안전하게 참조
val flutter = extensions.getByName("flutter") as groovy.lang.GroovyObject

android {
    namespace = "com.example.ar_memo_frontend"

    // ✅ ObjectFactory.property(...) 충돌 회피: getProperty 사용
    compileSdk = (flutter.getProperty("compileSdkVersion") as Int)
    ndkVersion = flutter.getProperty("ndkVersion") as String

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.ar_memo_frontend"
        minSdk = (flutter.getProperty("minSdkVersion") as Int)
        targetSdk = (flutter.getProperty("targetSdkVersion") as Int)
        versionCode = (flutter.getProperty("versionCode") as Int)
        versionName = flutter.getProperty("versionName") as String
        multiDexEnabled = true

        manifestPlaceholders["KAKAO_NATIVE_APP_KEY"] = "a04b18bad57c4a8b33e9eccada1f9748"
    }

    buildTypes {
        // ✅ 개발용 빌드에서는 코드/리소스 축소 모두 끄기
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        // ✅ 배포용 빌드에서는 축소 활성화 (원할 경우)
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// ✅ Kotlin Toolchain 17 강제
kotlin {
    jvmToolchain(17)
}
