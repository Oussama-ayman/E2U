-keep class androidx.lifecycle.DefaultLifecycleObserver

# Fix for Jackson databind missing classes
-dontwarn java.beans.**
-keep class java.beans.** { *; }

# Fix for OkHttp Conscrypt missing classes
-dontwarn org.conscrypt.**
-keep class org.conscrypt.** { *; }

# Fix for DOM implementation missing classes
-dontwarn org.w3c.dom.bootstrap.**
-keep class org.w3c.dom.bootstrap.** { *; }

# General Jackson rules
-keep @com.fasterxml.jackson.annotation.JsonIgnoreProperties class * { *; }
-keep class com.fasterxml.jackson.** { *; }
-keepnames class com.fasterxml.jackson.** { *; }
-dontwarn com.fasterxml.jackson.databind.**

# Keep all model classes that might be used with Jackson
-keepclassmembers class * {
    @com.fasterxml.jackson.annotation.* *;
}

# Firebase and Google Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Zego related classes
-keep class im.zego.** { *; }
-dontwarn im.zego.**

# R8 generated rules for missing classes
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.conscrypt.Conscrypt
-dontwarn org.conscrypt.OpenSSLProvider
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
