plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

fun quotedProperty(name: String, fallback: String = ""): String {
    val value = providers.gradleProperty(name).orElse(fallback).get()
    return "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""
}

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

}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2026.08.00")
    implementation(composeBom)
    androidTestImplementation(composeBom)

    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.appcompat:appcompat:1.8.0")
    implementation("androidx.core:core-ktx:1.19.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.11.0")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.11.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.11.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")

    implementation("com.mastercard.gateway:Mobile_SDK_Android:2.0.17") {
        // gateway-android-3ds still declares the retired support-v7 artifact even
        // though its 6.7.60 bytecode does not reference android.support classes.
        exclude(group = "com.android.support")
    }
    implementation(files("libs/benefitinappsdk-1.0.27.aar"))

    debugImplementation("androidx.compose.ui:ui-tooling")
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
