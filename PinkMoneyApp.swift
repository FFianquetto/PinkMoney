import SwiftData
import SwiftUI

@main
struct PinkMoneyApp: App {
    private let container: ModelContainer
    @StateObject private var ledger: LedgerStore
    @StateObject private var auth: AuthService
    @StateObject private var network: NetworkMonitor
    @StateObject private var notifications: NotificationService
    @StateObject private var sync: SyncManager

    init() {
        let container = LocalDatabase.makeContainer()
        let ledger = LedgerStore(container: container)
        let network = NetworkMonitor()
        let notifications = NotificationService()
        let gateway = FirebaseGateway()
        let auth = AuthService(container: container, gateway: gateway, network: network, ledger: ledger)
        let sync = SyncManager(container: container, auth: auth, network: network, gateway: gateway, ledger: ledger)

        network.onReconnect = { [weak sync] in
            Task { await sync?.syncPending() }
        }
        network.start()
        auth.afterAuthentication = { [weak sync] in
            await sync?.syncPending()
        }

        self.container = container
        _ledger = StateObject(wrappedValue: ledger)
        _auth = StateObject(wrappedValue: auth)
        _network = StateObject(wrappedValue: network)
        _notifications = StateObject(wrappedValue: notifications)
        _sync = StateObject(wrappedValue: sync)
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(ledger)
                .environmentObject(auth)
                .environmentObject(network)
                .environmentObject(notifications)
                .environmentObject(sync)
                .tint(PinkPalette.accent)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}
