import Flutter
import MapLibre
import UIKit

public class MapLibrePlugin: NSObject, FlutterPlugin {
    private static let requestHeaders = HostScopedRequestHeaders()

    public static func register(with registrar: FlutterPluginRegistrar) {
        requestHeaders.install()
        let channel = FlutterMethodChannel(
            name: "plugins.flutter.io/maplibre/request_headers",
            binaryMessenger: registrar.messenger()
        )
        let instance = MapLibrePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // register MapLibre view factory
        let factory = MapLibreViewFactory(withRegistrar: registrar)
        registrar.register(factory, withId: "plugins.flutter.io/maplibre")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard
            let arguments = call.arguments as? [String: Any],
            let host = arguments["host"] as? String
        else {
            result(
                FlutterError(
                    code: "invalid_arguments",
                    message: "Missing host.",
                    details: nil
                )
            )
            return
        }

        switch call.method {
        case "setRequestHeaders":
            guard let headers = arguments["headers"] as? [String: String] else {
                result(
                    FlutterError(
                        code: "invalid_arguments",
                        message: "Missing headers.",
                        details: nil
                    )
                )
                return
            }
            Self.requestHeaders.replace(host: host, headers: headers)
            result(nil)
        case "clearRequestHeaders":
            Self.requestHeaders.clear(host: host)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
