import Foundation
import Network

enum FoundationModelsBenchConnectivityObservation: String, Sendable {
    case connected
    case disconnected
    case connectionRequired
    case unknown

    var verifiesOfflineExperiment: Bool {
        self == .disconnected
    }

    var displayName: String {
        switch self {
        case .connected:
            "an active network path"
        case .disconnected:
            "no active network path"
        case .connectionRequired:
            "a network path that can connect on demand"
        case .unknown:
            "an unknown network state"
        }
    }

    init(status: NWPath.Status) {
        switch status {
        case .satisfied:
            self = .connected
        case .unsatisfied:
            self = .disconnected
        case .requiresConnection:
            self = .connectionRequired
        @unknown default:
            self = .unknown
        }
    }
}

enum FoundationModelsBenchConnectivityObserver {
    static func observe() async -> FoundationModelsBenchConnectivityObservation {
        let monitor = NWPathMonitor()
        let state = FoundationModelsBenchConnectivityObservationState()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                state.install(continuation)
                monitor.pathUpdateHandler = { path in
                    state.complete(with: FoundationModelsBenchConnectivityObservation(status: path.status))
                    monitor.cancel()
                }
                monitor.start(queue: DispatchQueue(label: "FoundationModelsBenchConnectivityObserver"))
            }
        } onCancel: {
            state.complete(with: .unknown)
            monitor.cancel()
        }
    }
}

enum FoundationModelsBenchOfflineResultPolicy {
    static func isSuccess(connectivityVerified: Bool, model: FoundationModelsBenchModel) -> Bool {
        connectivityVerified && model == .onDevice
    }
}

private final class FoundationModelsBenchConnectivityObservationState: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<FoundationModelsBenchConnectivityObservation, Never>?
    private var completedObservation: FoundationModelsBenchConnectivityObservation?

    func install(
        _ continuation: CheckedContinuation<FoundationModelsBenchConnectivityObservation, Never>
    ) {
        lock.lock()
        if let completedObservation {
            lock.unlock()
            continuation.resume(returning: completedObservation)
        } else {
            self.continuation = continuation
            lock.unlock()
        }
    }

    func complete(with observation: FoundationModelsBenchConnectivityObservation) {
        lock.lock()
        guard completedObservation == nil else {
            lock.unlock()
            return
        }
        completedObservation = observation
        let continuation = continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(returning: observation)
    }
}
