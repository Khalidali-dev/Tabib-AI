allprojects {
    // Automatically patch legacy proguard-android.txt in third-party plugins (e.g. fllama) for AGP 8+ compatibility
    val userHome = System.getProperty("user.home")
    val pubCacheDir = file("$userHome/.pub-cache/hosted/pub.dev")
    if (pubCacheDir.exists()) {
        pubCacheDir.walk().filter { it.name == "build.gradle" && it.path.contains("fllama") }.forEach { gradleFile ->
            var text = gradleFile.readText()
            var modified = false
            if (text.contains("proguard-android.txt")) {
                text = text.replace("proguard-android.txt", "proguard-android-optimize.txt")
                modified = true
            }
            if (text.contains("28.0.12433566")) {
                text = text.replace("28.0.12433566", "28.2.13676358")
                modified = true
            }
            if (text.contains("3.31.0")) {
                text = text.replace("3.31.0", "3.22.1")
                modified = true
            }
            if (modified) {
                gradleFile.writeText(text)
            }
        }
    }

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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
