import SwiftUI

extension MovementItem {
    init(_ expense: Expense) {
        self.init(
            id: expense.id,
            amount: expense.amount,
            category: expense.expenseCategory,
            date: expense.date,
            note: expense.note,
            isSynced: expense.isSynced
        )
    }
}

extension Ledger {
    init(expenses: [Expense], budget: Double) {
        self.init(items: expenses.map(MovementItem.init), budget: budget)
    }
}

// MARK: - Entorno

private struct LedgerKey: EnvironmentKey {
    static let defaultValue = Ledger.empty
}

extension EnvironmentValues {
    /// Libro de gastos calculado una sola vez en `MainTabView` y compartido por todas las pestañas.
    var ledger: Ledger {
        get { self[LedgerKey.self] }
        set { self[LedgerKey.self] = newValue }
    }
}
