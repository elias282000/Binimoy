pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "binimoy"
include(":app")

// Include Flutter
apply {
    from("${rootProject.projectDir}/../.android/include_flutter.groovy")
}
