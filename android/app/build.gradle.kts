import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.devtools.ksp")
}

val cloudProperties = Properties().apply {
    rootProject.file("supabase.properties").takeIf { it.isFile }?.inputStream()?.use(::load)
}
fun configLiteral(value: String): String = "\"" + value.replace("\\", "\\\\")
    .replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r") + "\""

android {
    namespace = "com.husseinabozina.taskmanagement"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.husseinabozina.taskmanagement"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0-android"
        buildConfigField("String", "SUPABASE_URL", configLiteral(cloudProperties.getProperty("SUPABASE_URL", "")))
        buildConfigField("String", "SUPABASE_CLIENT_KEY", configLiteral(cloudProperties.getProperty("SUPABASE_CLIENT_KEY", "")))
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        compose = true
        buildConfig = true
    }
    // Arabic UI and localized date picker must be available regardless of device language.
    bundle {
        language {
            enableSplit = false
        }
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.09.00")
    implementation(composeBom)
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.activity:activity-compose:1.11.0")
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.9.4")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.4")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.9.4")

    val roomVersion = "2.8.0"
    implementation("androidx.room:room-runtime:$roomVersion")
    implementation("androidx.room:room-ktx:$roomVersion")
    ksp("androidx.room:room-compiler:$roomVersion")
}
