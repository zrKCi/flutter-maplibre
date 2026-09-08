package com.github.josxha.maplibre

// if imports can't resolve:
// - remove all .idea/ folders
// - open example/android/build.gradle.kts as project
// - sync project to download dependencies

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.maplibre.android.location.permissions.PermissionsManager

/** MapLibrePlugin */
class MapLibrePlugin :
    FlutterPlugin,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    private var permissionsManager: PermissionsManager? = null
    private var requestHeadersChannel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        installHostScopedRequestHeadersInterceptor()
        requestHeadersChannel =
            MethodChannel(binding.binaryMessenger, requestHeadersChannelName).apply {
                setMethodCallHandler { call, result ->
                    val host = call.argument<String>("host")
                    if (host == null) {
                        result.error("invalid_arguments", "Missing host.", null)
                        return@setMethodCallHandler
                    }
                    when (call.method) {
                        "setRequestHeaders" -> {
                            val rawHeaders = call.argument<Map<*, *>>("headers")
                            val headers =
                                rawHeaders?.entries?.associate { entry ->
                                    entry.key as String to entry.value as String
                                }
                            if (headers == null) {
                                result.error(
                                    "invalid_arguments",
                                    "Missing headers.",
                                    null,
                                )
                            } else {
                                HostScopedRequestHeaders.replace(host, headers)
                                result.success(null)
                            }
                        }
                        "clearRequestHeaders" -> {
                            HostScopedRequestHeaders.clear(host)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
        binding
            .platformViewRegistry
            .registerViewFactory(
                "plugins.flutter.io/maplibre",
                MapLibreMapFactory(),
            )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        requestHeadersChannel?.setMethodCallHandler(null)
        requestHeadersChannel = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        permissionsManager?.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults,
        )
        return true
    }

    private companion object {
        const val requestHeadersChannelName =
            "plugins.flutter.io/maplibre/request_headers"
    }
}

class MapLibreMapFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?,
    ): PlatformView = MapLibreRegistry.flutterApi!!.createPlatformView(viewId)
}
