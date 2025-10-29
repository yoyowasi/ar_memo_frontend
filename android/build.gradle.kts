import com.android.build.gradle.LibraryExtension
import org.gradle.kotlin.dsl.configure
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.JavaVersion
import org.gradle.kotlin.dsl.withType
import org.gradle.kotlin.dsl.configure
import org.jetbrains.kotlin.gradle.plugin.KotlinBasePlugin // KotlinBasePlugin import 추가
import org.jetbrains.kotlin.gradle.dsl.JvmTarget


allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // 모든 프로젝트에 대해 Kotlin JVM 툴체인 17 강제
    // plugins.withType<KotlinBasePlugin> { ... } 블록을 사용하여 Kotlin 플러그인이 적용될 때 설정
    project.plugins.withType<org.jetbrains.kotlin.gradle.plugin.KotlinBasePlugin> {
        project.extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinProjectExtension>("kotlin") {
            jvmToolchain(17)
        }
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

    // project.evaluationDependsOn(":app") // 이 라인을 제거합니다.

    plugins.withId("com.android.library") {
        val android = extensions.getByType<LibraryExtension>()
        android.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }

        if (name == "ar_flutter_plugin") {
            android.namespace = "de.carius.ar_flutter_plugin"
            tasks.matching { it.name == "preBuild" }.configureEach {
                doFirst {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val original = manifestFile.readText()
                        val cleaned = original.replace(
                            Regex("\\s+package=\"io\\.carius\\.lars\\.ar_flutter_plugin\""),
                            "",
                        )
                        if (cleaned != original) {
                            manifestFile.writeText(cleaned)
                        }
                    }
                }
            }
        }
    }

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString() // Java 17로 통일
        targetCompatibility = JavaVersion.VERSION_17.toString() // Java 17로 통일
    }
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17) // Kotlin JVM 타깃 17로 통일
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
