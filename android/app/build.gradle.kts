plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

fun quotedProperty(name: String, fallback: String = ""): String {
    val value = providers.gradleProperty(name).orElse(fallback).get()
    return "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""
}

val tallaCiBuild = providers.gradleProperty("talla.ci").orElse("false").map(String::toBoolean).get()

android {
    namespace = "com.talla.speciality"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.talla.speciality"
        minSdk = 26
        targetSdk = 37
        versionCode = 1
        versionName = "0.1.0"

        buildConfigField("String", "SHOP_DOMAIN", quotedProperty("TALLA_SHOP_DOMAIN"))
        buildConfigField("String", "STOREFRONT_TOKEN", quotedProperty("TALLA_STOREFRONT_TOKEN"))
        buildConfigField("String", "BACKEND_URL", quotedProperty("TALLA_BACKEND_URL"))
        buildConfigField("long", "PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER", providers.gradleProperty("TALLA_PLAY_INTEGRITY_CLOUD_PROJECT_NUMBER").orElse("0").get() + "L")
        // The legacy BenefitPay SDK requires this merchant secret in the app.
        // Keep it out of source control and inject it from ~/.gradle/gradle.properties.
        buildConfigField("String", "BENEFITPAY_SDK_SECRET", quotedProperty("TALLA_BENEFITPAY_SDK_SECRET"))
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    if (tallaCiBuild) {
        sourceSets.getByName("main").java.srcDir("src/ciStubs/java")
    }

}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.08.00")
    val firebaseBom = platform("com.google.firebase:firebase-bom:34.18.0")
    implementation(composeBom)
    implementation(firebaseBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.appcompat:appcompat:1.8.0")
    implementation("androidx.core:core-ktx:1.19.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.11.0")
    implementation("androidx.glance:glance-appwidget:1.2.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("com.google.mlkit:text-recognition:16.0.1")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.android.play:integrity:1.6.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.10.2")

    if (!tallaCiBuild) {
        implementation("com.mastercard.gateway:Mobile_SDK_Android:2.0.17") {
            // gateway-android-3ds still declares the retired support-v7 artifact even
            // though its 6.7.60 bytecode does not reference android.support classes.
            exclude(group = "com.android.support")
        }
        implementation(files("libs/benefitinappsdk-1.0.27.aar"))
    }

    debugImplementation("androidx.compose.ui:ui-tooling")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
