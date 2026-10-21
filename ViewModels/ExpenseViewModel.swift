import Combine
import Foundation

/// Estado del formulario "Nuevo Registro". Guardar es 100% local y síncrono:
/// escribe en la base del iPhone, actualiza el saldo y solo después avisa a la cola de sincronización.
@MainActor
final class ExpenseViewModel: ObservableObject {
    @Published var amountText = ""
    @Published var category: ExpenseCategory = .despensa
    @Published var note = ""
    @Published var errorMessage: String?

    /// Devuelve `true` si el gasto quedó guardado y el modal puede cerrarse.
    func save(to ledger: LedgerStore, sync: SyncManager) -> Bool {
        guard let amount = MoneyFormat.parse(amountText) else {
            errorMessage = PinkMoneyError.invalidAmount.localizedDescription
            return false
        }
        do {
            // 1. Guarda local y 2. actualiza el saldo (el store recalcula al instante).
            try ledger.add(amount: amount, category: category, note: note)
            errorMessage = nil
            // 3. La cola de espera corre aparte y nunca bloquea al usuario.
            Task { await sync.syncPending() }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
