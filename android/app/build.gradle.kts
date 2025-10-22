// android/app/build.gradle.kts  ← 전체 교체

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ar_memo_frontend"

    // ✅ 플러그인/의존성 요구사항 충족
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.ar_memo_frontend"
        minSdk = 24
        targetSdk = 36        // 원하면 34/35도 가능하지만 최신 권장치로 맞춤
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    // ✅ AGP 8.x 권장: JDK 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // ✅ Debug: 축소 OFF / Release: 코드+리소스 축소 ON
    buildTypes {
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // ✅ 코틀린 소스 디렉토리(있으면)
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    // ✅ ARCore JNI 충돌 방지 + 일반 리소스 제외
    packaging {
        jniLibs {
            pickFirsts += listOf(
                "lib/arm64-v8a/libarcore_sdk_jni.so",
                "lib/armeabi-v7a/libarcore_sdk_jni.so",
                "lib/x86/libarcore_sdk_jni.so",
                "lib/x86_64/libarcore_sdk_jni.so"
            )
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

// Flutter 소스 루트
flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.ar:core:1.33.0")
    implementation(kotlin("stdlib-jdk8"))
}
