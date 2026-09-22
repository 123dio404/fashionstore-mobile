package com.example.fashionstore_mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * CU17 (Vestidor Virtual AR) — puente nativo hacia ARCore.
 *
 * Flutter no renderiza la sesión AR: la delega en **Scene Viewer** (Google Play
 * Services for AR), que aporta la cámara en vivo, la detección y el anclaje de planos
 * (piso/mesa), la rotación 360°, la escala real 1:1 y la captura de foto. El canal
 * `com.fashionstore/ar` expone:
 *
 *  - `availability`            → soporte AR del equipo (ARCore, Scene Viewer, hardware).
 *  - `requestCameraPermission` → permiso de cámara con el diálogo real del sistema.
 *  - `startSession`            → abre la sesión AR del producto (.glb).
 *  - `installArCore`           → Play Store para instalar/actualizar ARCore.
 */
class MainActivity : FlutterActivity() {

    private var pendingCameraResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "availability" -> result.success(availability())
                    "requestCameraPermission" -> requestCameraPermission(result)
                    "startSession" -> result.success(
                        startSession(
                            modelUrl = call.argument<String>("url").orEmpty(),
                            title = call.argument<String>("title").orEmpty(),
                            mode = call.argument<String>("mode").orEmpty(),
                        )
                    )
                    "installArCore" -> result.success(openArCoreStoreListing())
                    else -> result.notImplemented()
                }
            }
    }

    // ------------------------------------------------------------------ CU17 --

    /** Soporte AR del equipo, para que Flutter decida qué mostrar. */
    private fun availability(): Map<String, Any> {
        val viewer = resolveSceneViewerIntent("", DEFAULT_TITLE, MODE_AR_PREFERRED)
        val arCore = isPackageInstalled(AR_CORE_PACKAGE)
        return mapOf(
            "deviceSupported" to packageManager.hasSystemFeature(FEATURE_CAMERA_AR),
            "arCoreInstalled" to arCore,
            "sceneViewerInstalled" to (viewer != null),
            "message" to when {
                viewer == null -> "Instala Google Play Services para AR (ARCore)."
                arCore -> "ARCore listo: detección de planos y escala 1:1."
                else -> "Scene Viewer disponible a través de la app de Google."
            },
        )
    }

    /** Solicita el permiso de cámara al sistema y responde con el resultado real. */
    private fun requestCameraPermission(result: MethodChannel.Result) {
        if (checkSelfPermission(android.Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingCameraResult = result
        requestPermissions(arrayOf(android.Manifest.permission.CAMERA), CAMERA_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != CAMERA_REQUEST_CODE) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingCameraResult?.success(granted)
        pendingCameraResult = null
    }

    /** Abre la sesión AR del modelo con Scene Viewer. */
    private fun startSession(modelUrl: String, title: String, mode: String): Map<String, Any> {
        if (modelUrl.isBlank()) {
            return launchResult(false, false, "El producto no tiene un modelo 3D (.glb).")
        }
        val safeTitle = title.ifBlank { DEFAULT_TITLE }
        val safeMode = mode.ifBlank { MODE_AR_PREFERRED }
        val intent = resolveSceneViewerIntent(modelUrl, safeTitle, safeMode)
            ?: return launchResult(
                false,
                true,
                "No hay visor AR en este equipo. Instala Google Play Services para AR.",
            )
        return try {
            startActivity(intent)
            launchResult(true, false, "Sesión AR abierta: ancla el modelo al piso o la mesa.")
        } catch (error: ActivityNotFoundException) {
            launchResult(false, true, "No fue posible abrir el visor AR.")
        }
    }

    private fun launchResult(launched: Boolean, needsInstall: Boolean, message: String) =
        mapOf("launched" to launched, "needsInstall" to needsInstall, "message" to message)

    /**
     * Busca un visor disponible en este orden: Scene Viewer de ARCore, el formato
     * `intent://` (versiones antiguas de ARCore) y el Scene Viewer que publica la app
     * de Google — mismo criterio que usa `model_viewer_plus` para máxima cobertura.
     */
    private fun resolveSceneViewerIntent(modelUrl: String, title: String, mode: String): Intent? {
        val url = sceneViewerUrl(modelUrl, title, mode)
        val candidates = listOf(
            Intent(Intent.ACTION_VIEW, url).setPackage(AR_CORE_PACKAGE),
            intentUrl(url, modelUrl, title, mode),
            Intent(Intent.ACTION_VIEW, url).setPackage(GOOGLE_APP_PACKAGE),
        )
        return candidates.firstOrNull { it != null && it.resolveActivity(packageManager) != null }
    }

    /** URL oficial de Scene Viewer. `resizable=false` fija la escala real 1:1. */
    private fun sceneViewerUrl(modelUrl: String, title: String, mode: String): Uri =
        Uri.Builder()
            .scheme("https")
            .authority(SCENE_VIEWER_HOST)
            .path(SCENE_VIEWER_PATH)
            .appendQueryParameter("file", modelUrl)
            .appendQueryParameter("mode", mode)
            .appendQueryParameter("title", title)
            .appendQueryParameter("resizable", "false")
            .build()

    /** Variante `intent://arvr.google.com/scene-viewer/1.0` con fallback de navegador. */
    private fun intentUrl(url: Uri, modelUrl: String, title: String, mode: String): Intent? =
        try {
            val raw = "intent://$SCENE_VIEWER_HOST$SCENE_VIEWER_PATH" +
                "?file=${Uri.encode(modelUrl)}" +
                "&mode=$mode" +
                "&title=${Uri.encode(title)}" +
                "&resizable=false" +
                "#Intent;scheme=https;package=$AR_CORE_PACKAGE;" +
                "action=android.intent.action.VIEW;" +
                "S.browser_fallback_url=${Uri.encode(url.toString())};end;"
            Intent.parseUri(raw, Intent.URI_INTENT_SCHEME)
        } catch (error: Exception) {
            null
        }

    private fun isPackageInstalled(packageName: String): Boolean =
        try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (error: PackageManager.NameNotFoundException) {
            false
        }

    /** Play Store para instalar o actualizar Google Play Services for AR. */
    private fun openArCoreStoreListing(): Boolean {
        val market = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=$AR_CORE_PACKAGE"))
        if (market.resolveActivity(packageManager) != null) {
            startActivity(market)
            return true
        }
        val web = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("https://play.google.com/store/apps/details?id=$AR_CORE_PACKAGE"),
        )
        if (web.resolveActivity(packageManager) != null) {
            startActivity(web)
            return true
        }
        return false
    }

    private companion object {
        const val CHANNEL = "com.fashionstore/ar"
        const val AR_CORE_PACKAGE = "com.google.ar.core"
        const val GOOGLE_APP_PACKAGE = "com.google.android.googlequicksearchbox"
        const val SCENE_VIEWER_HOST = "arvr.google.com"
        const val SCENE_VIEWER_PATH = "/scene-viewer/1.0"
        const val FEATURE_CAMERA_AR = "android.hardware.camera.ar"
        const val MODE_AR_PREFERRED = "ar_preferred"
        const val DEFAULT_TITLE = "Vestidor Virtual AR"
        const val CAMERA_REQUEST_CODE = 4711
    }
}
