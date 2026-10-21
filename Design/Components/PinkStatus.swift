import SwiftUI

/// Resultado de una acción de formulario (éxito o error).
struct PinkFeedback: Equatable {
    let text: String
    let isError: Bool

    static func success(_ text: String) -> PinkFeedback { PinkFeedback(text: text, isError: false) }
    static func failure(_ error: Error) -> PinkFeedback { PinkFeedback(text: error.localizedDescription, isError: true) }
}

/// Aviso compacto (sin internet, cola de sincronización, modo local…).
struct StatusChip: View {
    let icon: String
    let text: String
    var tint: Color = PinkPalette.inkSoft

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
            Text(text)
                .font(.footnote.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: PinkTheme.Radius.chip, style: .continuous))
    }
}

extension StatusChip {
    init(feedback: PinkFeedback) {
        self.init(
            icon: feedback.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill",
            text: feedback.text,
            tint: feedback.isError ? PinkPalette.danger : PinkPalette.success
        )
    }

    init(error text: String) {
        self.init(icon: "exclamationmark.circle.fill", text: text, tint: PinkPalette.danger)
    }
}

/// Etiqueta pequeña redondeada.
struct PinkBadge: View {
    let text: String
    var systemImage: String?
    var tint: Color = PinkPalette.accent

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.14), in: Capsule())
    }
}

/// Banner rojo del flujo "¿Presupuesto al límite? Sí".
struct PinkAlertBanner: View {
    let title: String
    let message: String
    var isCritical = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCritical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(message)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(PinkPalette.danger)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            PinkPalette.danger.opacity(0.11),
            in: RoundedRectangle(cornerRadius: PinkTheme.Radius.row, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PinkTheme.Radius.row, style: .continuous)
                .strokeBorder(PinkPalette.danger.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

extension PinkAlertBanner {
    init(_ alert: DashboardViewModel.LimitAlert) {
        self.init(title: alert.title, message: alert.message, isCritical: alert.isCritical)
    }
}

/// Estado vacío con el Cerdo.
struct EmptyStateView: View {
    let title: String
    let message: String
    var mascotSize: CGFloat = 92

    var body: some View {
        VStack(spacing: 10) {
            CerdoMascot(size: mascotSize)
            Text(title)
                .font(PinkTheme.Font.title(.headline))
                .foregroundStyle(PinkPalette.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.footnote)
                .foregroundStyle(PinkPalette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
