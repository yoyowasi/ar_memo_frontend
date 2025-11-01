// android/build.gradle.kts

import com.android.build.gradle.LibraryExtension
import org.gradle.kotlin.dsl.configure
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.JavaVersion

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()

    }
    tasks.withType<KotlinCompile>().configureEach {
        kotlinOptions {
            jvmTarget = JavaVersion.VERSION_17.toString()
        }
    }
}

// 🟢 [수정] 코틀린 버전을 강제하던 이 블록 전체를 삭제합니다.
// configurations.all {
//    resolutionStrategy {
//        eachDependency {
//            if (requested.group == "org.jetbrains.kotlin") {
//                useVersion("1.8.0") // Try a slightly older Kotlin version
//     
//        }
//        }
//    }
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}