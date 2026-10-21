import Combine
import Foundation
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true

    var onReconnect: (@MainActor () -> Void)?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "pinkmoney.network")
    private var started = false

    func start() {
        guard !started else { return }
        started = true
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor in
                guard let self else { return }
                let previous = self.isConnected
                self.isConnected = connected
                if previous == false && connected {
                    self.onReconnect?()
                }
            }
        }
        monitor.start(queue: queue)
    }
}
