import Foundation

/// Modelo de presentación del Dashboard: textos y estados derivados del `Ledger`.
struct DashboardViewModel {
    struct LimitAlert {
        let title: String
        let message: String
        let isCritical: Bool
    }

    let ledger: Ledger
    let email: String?
    var displayName: String?

    var greetingName: String {
        if let first = displayName?.split(separator: " ").first, !first.isEmpty {
            return String(first)
        }
        let name = email?.split(separator: "@").first.map(String.init) ?? "estudiante"
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    var recent: [MovementItem] { ledger.recent(6) }
    var hasMovements: Bool { !ledger.items.isEmpty }

    /// Rama "¿Presupuesto al límite? Sí" del diagrama de flujo.
    var limitAlert: LimitAlert? {
        guard ledger.isAtLimit else { return nil }
        return LimitAlert(
            title: "El Cerdo avisa del límite",
            message: ledger.isOverBudget
                ? "Ya rebasaste tu límite mensual."
                : "¡Cuidado! Estás a punto de rebasar tu límite mensual",
            isCritical: ledger.isOverBudget
        )
    }
}
