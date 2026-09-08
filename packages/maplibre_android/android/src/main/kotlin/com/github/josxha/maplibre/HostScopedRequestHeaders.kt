package com.github.josxha.maplibre

import java.util.Locale
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean
import okhttp3.Dispatcher
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import org.maplibre.android.module.http.HttpRequestUtil

internal object HostScopedRequestHeaders {
    private val headersByHost = ConcurrentHashMap<String, Map<String, String>>()

    fun replace(
        host: String,
        headers: Map<String, String>,
    ) {
        val normalizedHost = host.lowercase(Locale.ROOT)
        if (headers.isEmpty()) {
            headersByHost.remove(normalizedHost)
        } else {
            headersByHost[normalizedHost] = headers.toMap()
        }
    }

    fun clear(host: String) {
        headersByHost.remove(host.lowercase(Locale.ROOT))
    }

    fun applyTo(request: Request): Request {
        val headers = headersByHost[request.url.host.lowercase(Locale.ROOT)]
            ?: return request
        return request
            .newBuilder()
            .apply {
                headers.forEach { (name, value) -> header(name, value) }
            }.build()
    }
}

internal object HostScopedRequestHeadersInterceptor : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response =
        chain.proceed(HostScopedRequestHeaders.applyTo(chain.request()))
}

internal fun installHostScopedRequestHeadersInterceptor() {
    if (!requestHeadersInterceptorInstalled.compareAndSet(false, true)) return
    val dispatcher = Dispatcher().apply { maxRequestsPerHost = 20 }
    val client =
        OkHttpClient
            .Builder()
            .dispatcher(dispatcher)
            .addInterceptor(HostScopedRequestHeadersInterceptor)
            .build()
    HttpRequestUtil.setOkHttpClient(client)
}

private val requestHeadersInterceptorInstalled = AtomicBoolean()
