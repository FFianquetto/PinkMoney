import Combine
import Foundation
import os
import SwiftData

/// Cola de sincronización con Firestore. Con `PinkTheme.cloudSyncEnabled == false`
/// no hace nada y la app trabaja solo con la base local.
@MainActor
final class SyncManager: ObservableObject {
    @Published private(set) var lastSyncError: String?

    private let container: ModelContainer
    private let auth: AuthService
    private let network: NetworkMonitor
    private let gateway: FirebaseGateway
    private let ledger: LedgerStore
    private let logger = Logger(subsystem: "com.pinkmoney.app", category: "sync")
    private var isSyncing = false
    private var queued = false

    init(
        container: ModelContainer,
        auth: AuthService,
        network: NetworkMonitor,
        gateway: FirebaseGateway,
        ledger: LedgerStore
    ) {
        self.container = container
        self.auth = auth
        self.network = network
        self.gateway = gateway
        self.ledger = ledger
    }

    /// Rama "¿Conexión a internet?" del diagrama: con red sube la cola, sin red los gastos esperan
    /// guardados en el iPhone con `isSynced = false`.
    func syncPending() async {
        if isSyncing {
            queued = true
            return
        }
        isSyncing = true
        defer {
            isSyncing = false
            if queued {
                queued = false
                Task { await self.syncPending() }
            }
        }

        guard auth.canSyncToCloud, network.isConnected else { return }
        lastSyncError = nil
        do {
            try await syncProfile()
            try await pushPending()
            try await pullExpenses()
        } catch PinkMoneyError.network {
            lastSyncError = "Sin conexión con Firebase. Los gastos siguen en el iPhone."
        } catch {
            lastSyncError = error.localizedDescription
        }
        ledger.reload()
    }

    private func syncProfile() async throws {
        guard auth.canSyncToCloud, let user = auth.currentUser else { return }
        let token = try await auth.validToken()
        if auth.isBudgetDirty {
            try await gateway.upsertUser(
                uid: user.id,
                email: user.email,
                monthlyBudget: user.monthlyBudget,
                token: token
            )
            auth.clearBudgetDirty()
            return
        }

        let remote = try await gateway.fetchUser(uid: user.id, token: token)
        if let remoteBudget = remote?.monthlyBudget {
            if remoteBudget != user.monthlyBudget {
                try auth.applyRemoteBudget(remoteBudget)
            }
        } else {
            try await gateway.upsertUser(
                uid: user.id,
                email: user.email,
                monthlyBudget: user.monthlyBudget,
                token: token
            )
        }
    }

    private func pushPending() async throws {
        let repository = SwiftDataExpenseRepository(context: container.mainContext)
        let pending = try repository.fetchPending()
        guard !pending.isEmpty else { return }
        let token = try await auth.validToken()
        guard let uid = auth.currentUser?.id else { return }

        var failed = 0
        for expense in pending {
            var payload = expense.payload()
            payload.isSynced = true
            do {
                try await gateway.upsertExpense(payload, uid: uid, token: token)
                try repository.markSynced(id: payload.id)
            } catch {
                failed += 1
                logger.error("Gasto en cola: \(error.localizedDescription, privacy: .public)")
            }
        }
        if failed > 0 {
            let noun = failed == 1 ? "gasto" : "gastos"
            lastSyncError = "Hay \(failed) \(noun) en cola. Se reintentan solos."
        }
    }

    private func pullExpenses() async throws {
        let token = try await auth.validToken()
        guard let uid = auth.currentUser?.id else { return }
        let remote = try await gateway.fetchExpenses(uid: uid, token: token)
        try SwiftDataExpenseRepository(context: container.mainContext).importCloud(remote)
    }
}
