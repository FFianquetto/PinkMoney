import Combine
import Foundation
import SwiftData

/// Único punto de lectura y escritura de gastos y presupuesto, siempre sobre la base local.
/// Cada escritura recalcula el `Ledger` en el momento, así el contador de la interfaz
/// se actualiza al instante y sin depender de la red.
@MainActor
final class LedgerStore: ObservableObject {
    @Published private(set) var ledger = Ledger.empty
    @Published private(set) var loadError: String?

    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
        reload()
    }

    private var expenses: SwiftDataExpenseRepository {
        SwiftDataExpenseRepository(context: container.mainContext)
    }

    private var users: SwiftDataUserRepository {
        SwiftDataUserRepository(context: container.mainContext)
    }

    /// Lee la base local y recalcula todos los números. Es seguro llamarlo las veces que haga falta.
    func reload() {
        do {
            let all = try expenses.fetchAll()
            let budget = try users.current()?.monthlyBudget ?? PinkTheme.defaultBudget
            let next = Ledger(expenses: all, budget: budget)
            if next != ledger {
                ledger = next
            }
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    /// Guarda un gasto en la base local y actualiza el contador. No espera a ninguna red.
    func add(amount: Double, category: ExpenseCategory, note: String) throws {
        guard amount > 0, amount <= MoneyFormat.maxAmount else { throw PinkMoneyError.invalidAmount }
        let cleaned = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let stored = cleaned.isEmpty ? nil : String(cleaned.prefix(240))
        _ = try expenses.insert(amount: amount, category: category, note: stored)
        reload()
    }

    func delete(id: UUID) throws {
        try expenses.delete(id: id)
        reload()
    }
}
