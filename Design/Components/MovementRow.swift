import SwiftUI

/// Fila de "Últimos movimientos": ícono de categoría, nota, fecha y monto.
struct MovementRow: View {
    let movement: MovementItem

    var body: some View {
        HStack(spacing: 14) {
            CategoryBadge(category: movement.category)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PinkPalette.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PinkPalette.inkSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text("−\(MoneyFormat.currency(movement.amount))")
                    .font(PinkTheme.Font.amount(.body))
                    .foregroundStyle(PinkPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                syncStatusIcon
            }
        }
        .padding(14)
        .pinkSurface()
    }

    /// Solo con la nube activa se muestra el estado de la cola; en modo local no aparece ningún ícono.
    @ViewBuilder
    private var syncStatusIcon: some View {
        if PinkTheme.cloudSyncEnabled {
            Image(systemName: movement.isSynced ? "checkmark.icloud" : "tray.full")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(movement.isSynced ? PinkPalette.success : PinkPalette.warning)
                .accessibilityLabel(movement.isSynced ? "Sincronizado" : "En cola de espera")
        }
    }

    private var title: String {
        movement.note.flatMap { $0.isEmpty ? nil : $0 } ?? movement.category.title
    }

    private var subtitle: String {
        let date = MoneyFormat.movementDate(movement.date)
        return movement.note?.isEmpty == false ? "\(movement.category.title) · \(date)" : date
    }
}
