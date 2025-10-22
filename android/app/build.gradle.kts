// android/app/build.gradle.kts  (전체 교체)

plugins {
    id("com.android.application")
    id("kotlin-android")               // 또는 id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.ar_memo_frontend"

    // ❗ flutter.extra 사용 금지 — 고정값으로 명시
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.ar_memo_frontend"
        minSdk = 24            // ARCore/AR 플러그인은 보통 24 이상 권장
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    // AGP 8.x 이상 + JDK 17 권장
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // 🔧 Debug는 축소 OFF / Release는 코드+리소스 축소 ON
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

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
