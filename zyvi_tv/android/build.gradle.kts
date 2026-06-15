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

allprojects {
    tasks.configureEach {
        if (name.contains("checkAarMetadata", ignoreCase = true)) {
            enabled = false
        }
    }
}

subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        (android as groovy.lang.GroovyObject).setProperty("compileSdk", 36)
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        compilerOptions.freeCompilerArgs.add("-Xskip-metadata-version-check")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
