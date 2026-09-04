allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Correctif de compatibilité AGP 9 pour flutter_tts 4.x
subprojects {
    afterEvaluate {
        if (project.name == "flutter_tts") {
            project.plugins.withId("com.android.library") {
                val android = project.extensions.findByName("android")
                    as? com.android.build.gradle.LibraryExtension
                android?.compileSdk = 35
            }
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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
