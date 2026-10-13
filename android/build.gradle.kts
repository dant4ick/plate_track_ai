allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Flutter plugins disagree about their JVM target: tflite_flutter declares
// neither compileOptions nor kotlinOptions (so its Kotlin follows the Gradle
// daemon's JDK 21), while camera_android_camerax pins Java to 17. AGP fails any
// module whose Java and Kotlin targets differ, so align every subproject on 17 —
// the AGP 8 / Flutter default, and the highest any plugin here asks for.
//
// Only the Kotlin side is pinned here. A plugin's Java target cannot be
// overridden from the root: AGP owns source/targetCompatibility, and
// tflite_flutter loads its own AGP via a buildscript classpath, so its
// extension is a different class than the one this file can see. The
// leftover Java-11-vs-Kotlin-17 gap in that module is downgraded from error
// to warning by kotlin.jvm.target.validation.mode in gradle.properties —
// both halves still dex to the same DEX, so the split is harmless.
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
