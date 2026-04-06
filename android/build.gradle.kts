// Standard root build.gradle.kts for Flutter with cross-drive path handling.
// If the project is on a different drive than the Pub cache (E: vs C:), 
// using '../../build' can sometimes cause "different roots" errors.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Default build directory setup (staying within the android folder if needed)
// Using projectDirectory.dir("../build") to ensure consistent path resolution across drive roots.
rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("../build"))
subprojects {
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.get().dir(project.name))
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
