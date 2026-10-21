import SwiftUI

struct DashboardView: View {
    /// Cuando cambia, el scroll vuelve al inicio (por ejemplo, después de guardar un gasto).
    var scrollToTopToken = 0
    var onOpenRadiography: () -> Void = {}
    var onOpenMovements: () -> Void = {}

    @Environment(\.ledger) private var ledger
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var network: NetworkMonitor
    @EnvironmentObject private var sync: SyncManager
    @EnvironmentObject private var store: LedgerStore
    @State private var showSheet = false
    @State private var savedTick = 0
    @State private var deleteError: String?

    var body: some View {
        let model = DashboardViewModel(ledger: ledger, email: auth.currentUser?.email, displayName: auth.currentUser?.displayName)
        NavigationStack {
            PinkScreen {
                PinkScrollView(scrollToTopToken: scrollToTopToken + savedTick) {
                    header(model)
                    HeroBalanceCard(ledger: ledger)
                    statusStack(model)

                    PrimaryDarkButton(title: "+ Registrar Gasto") {
                        showSheet = true
                    }

                    recentSection(model)

                    PinkIconRow(
                        systemImage: "chart.pie.fill",
                        title: "Radiografía financiera",
                        message: "Descubre dónde se fuga tu dinero.",
                        action: onOpenRadiography
                    )
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .newExpenseSheet(isPresented: $showSheet) { savedTick += 1 }
        }
    }

    // MARK: Secciones

    private func header(_ model: DashboardViewModel) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("PINK MONEY").pinkEyebrow(tracking: 1.6)
                    if auth.isLocalMode {
                        PinkBadge(text: "Modo local", systemImage: "iphone", tint: PinkPalette.sageDeep)
                    }
                }
                Text("Hola, \(model.greetingName)")
                    .font(PinkTheme.Font.title(.title))
                    .foregroundStyle(PinkPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("Así va tu mes.")
                    .font(.subheadline)
                    .foregroundStyle(PinkPalette.inkSoft)
            }
            Spacer(minLength: 0)
            CerdoMascot(size: 78)
        }
    }

    @ViewBuilder
    private func statusStack(_ model: DashboardViewModel) -> some View {
        // Los avisos de red solo aplican cuando la sincronización en la nube está activa.
        let showsOffline = PinkTheme.cloudSyncEnabled && !network.isConnected
        let showsStatus = model.limitAlert != nil || showsOffline || sync.lastSyncError != nil
        if showsStatus {
            VStack(spacing: 10) {
                if let alert = model.limitAlert {
                    PinkAlertBanner(alert)
                }
                if showsOffline {
                    StatusChip(
                        icon: "wifi.slash",
                        text: "Sin internet. Los gastos se guardan en el iPhone y quedan en cola de espera.",
                        tint: PinkPalette.warning
                    )
                }
                if let lastSyncError = sync.lastSyncError {
                    StatusChip(icon: "icloud.slash", text: lastSyncError)
                }
            }
        }
    }

    private func recentSection(_ model: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PinkSectionHeader("Últimos movimientos", eyebrow: "Historial") {
                if model.hasMovements {
                    Button(action: onOpenMovements) {
                        HStack(spacing: 4) {
                            Text("Ver todo")
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PinkPalette.accent)
                    }
                }
            }

            if model.hasMovements {
                VStack(spacing: 10) {
                    ForEach(model.recent) { movement in
                        SwipeToDelete(onDelete: { delete(movement) }) {
                            MovementRow(movement: movement)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                    if let deleteError {
                        StatusChip(error: deleteError)
                    }
                    Text("Desliza un movimiento a la izquierda para borrarlo.")
                        .font(.caption)
                        .foregroundStyle(PinkPalette.inkFaint)
                        .frame(maxWidth: .infinity)
                }
            } else {
                PinkCard {
                    EmptyStateView(
                        title: "Todavía no hay movimientos",
                        message: "Registra tu primer gasto hormiga y aparece aquí al instante."
                    )
                }
            }
        }
    }

    /// Borra de la base local y recalcula el contador. Devuelve `false` si falló.
    private func delete(_ movement: MovementItem) -> Bool {
        do {
            try store.delete(id: movement.id)
            deleteError = nil
            return true
        } catch {
            deleteError = error.localizedDescription
            return false
        }
    }
}
