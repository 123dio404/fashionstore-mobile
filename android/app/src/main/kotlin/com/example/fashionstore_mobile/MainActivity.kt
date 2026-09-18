package com.example.fashionstore_mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.fashionstore/ar")
            .setMethodCallHandler { call, result ->
                if (call.method == "startSession") {
                    result.error(
                        "AR_NOT_CONFIGURED",
                        "Configure an ARCore host implementation before enabling AR.",
                        null
                    )
                } else {
                    result.notImplemented()
                }
            }
    }
}
