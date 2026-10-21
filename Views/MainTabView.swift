import SwiftUI
import UIKit

/// Menú principal con barra inferior de íconos. Toma el `Ledger` del `LedgerStore` (base local)
/// y lo comparte con las pestañas por el entorno. También dispara el aviso de límite.
struct MainTabView: View {
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var sync: SyncManager
    @State private var selection: AppTab = .dashboard
    @State private var showNewExpense = false
    @State private var keyboardVisible = false
    @State private var barHeight: CGFloat = 84
    @State private var balanceScrollToken = 0

    enum AppTab: Hashable, CaseIterable {
        case dashboard
        case movements
        case radiography
        case profile
    }

    private let leadingItems: [PinkTabBar<AppTab>.Item] = [
        .init(tag: .dashboard, title: "Inicio", symbol: "house"),
        .init(tag: .movements, title: "Movimientos", symbol: "list.bullet.rectangle")
    ]

    private let trailingItems: [PinkTabBar<AppTab>.Item] = [
        .init(tag: .radiography, title: "Radiografía", symbol: "chart.pie"),
        .init(tag: .profile, title: "Perfil", symbol: "person.crop.circle")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Todas las pestañas viven a la vez para conservar su scroll y estado al cambiar.
            ZStack {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    page(for: tab)
                        .opacity(selection == tab ? 1 : 0)
                        .allowsHitTesting(selection == tab)
                        .accessibilityHidden(selection != tab)
                }
            }
            // Cada scroll deja este espacio al final: la barra flota encima y nunca tapa contenido.
            .environment(\.barClearance, keyboardVisible ? 0 : barHeight + 12)

            if !keyboardVisible {
                PinkTabBar(
                    leading: leadingItems,
                    trailing: trailingItems,
                    selection: $selection,
                    onAdd: { showNewExpense = true }
                )
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { barHeight = $0 }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: keyboardVisible)
        .newExpenseSheet(isPresented: $showNewExpense) {
            showBalance()
        }
        .background(PinkPalette.canvas.ignoresSafeArea())
        .environment(\.ledger, store.ledger)
        .onChange(of: store.ledger.alertKey) { _, _ in
            checkBudget()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            keyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardVisible = false
        }
        .task {
            store.reload()
            checkBudget()
            await sync.syncPending()
        }
    }

    @ViewBuilder
    private func page(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(
                scrollToTopToken: balanceScrollToken,
                onOpenRadiography: { selection = .radiography },
                onOpenMovements: { selection = .movements }
            )
        case .movements:
            NavigationStack { AllMovementsView() }
        case .radiography:
            FinancialRadiographyView()
        case .profile:
            ProfileView()
        }
    }

    /// Tras guardar un gasto se muestra la pantalla de balance, arriba, con el contador ya actualizado.
    private func showBalance() {
        withAnimation(.spring(duration: 0.35, bounce: 0.2)) {
            selection = .dashboard
        }
        balanceScrollToken += 1
    }

    private func checkBudget() {
        notifications.checkBudgetThreshold(
            currentTotal: store.ledger.monthSpent,
            limit: store.ledger.budget
        )
    }
}
