# ---------------------------------------------------------------------------
# Reglas de R8 para spotired
#
# R8 esta SIEMPRE activo en los builds release de Flutter y no se puede
# desactivar. En debug no corre: de ahi que la notificacion de reproduccion
# apareciera en debug y no en el APK.
#
# AudioService se instancia desde el AndroidManifest (AGP lo conserva solo),
# pero las clases que usa para construir la sesion de medios y la notificacion
# se resuelven por reflexion. R8 las renombra y AudioService lanza una
# excepcion al montar la notificacion.
# ---------------------------------------------------------------------------

# audio_service / just_audio_background
-keep class com.ryanheise.audioservice.** { *; }
-keep interface com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

# just_audio
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# Sesion de medios y notificacion multimedia (ExoPlayer / media3 / media compat)
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# Mantiene los nombres de metodo en las trazas para poder diagnosticar
-keepattributes SourceFile,LineNumberTable,*Annotation*,Signature,InnerClasses
