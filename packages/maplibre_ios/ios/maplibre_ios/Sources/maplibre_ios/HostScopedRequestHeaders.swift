import Foundation
import MapLibre

final class HostScopedRequestHeaders: NSObject, MLNNetworkConfigurationDelegate {
    private let lock = NSLock()
    private var headersByHost: [String: [String: String]] = [:]
    private var previousDelegate: MLNNetworkConfigurationDelegate?

    func install() {
        let configuration = MLNNetworkConfiguration.sharedManager
        guard configuration.delegate !== self else { return }
        previousDelegate = configuration.delegate
        configuration.delegate = self
    }

    func replace(host: String, headers: [String: String]) {
        lock.lock()
        defer { lock.unlock() }
        let normalizedHost = host.lowercased()
        if headers.isEmpty {
            headersByHost.removeValue(forKey: normalizedHost)
        } else {
            headersByHost[normalizedHost] = headers
        }
    }

    func clear(host: String) {
        lock.lock()
        defer { lock.unlock() }
        headersByHost.removeValue(forKey: host.lowercased())
    }

    func willSend(_ request: NSMutableURLRequest) -> NSMutableURLRequest {
        let transformedRequest = previousDelegate?.willSend?(request) ?? request
        guard let host = transformedRequest.url?.host?.lowercased() else {
            return transformedRequest
        }

        lock.lock()
        let headers = headersByHost[host]
        lock.unlock()

        headers?.forEach { name, value in
            transformedRequest.setValue(value, forHTTPHeaderField: name)
        }
        return transformedRequest
    }
}
