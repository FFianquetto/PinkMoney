import SwiftUI

/// Estado visual del presupuesto: salvia mientras hay holgura, rosa cerca del límite, rojo al rebasar.
enum BudgetTone {
    case calm
    case caution
    case over

    init(ratio: Double) {
        if ratio >= 1 {
            self = .over
        } else if ratio >= 0.75 {
            self = .caution
        } else {
            self = .calm
        }
    }

    var color: Color {
        switch self {
        case .calm: PinkPalette.sage
        case .caution: PinkPalette.rose
        case .over: PinkPalette.danger
        }
    }
}

/// Barra de progreso genérica. La usan el presupuesto y el desglose por categoría.
struct PinkProgressBar: View {
    let fraction: Double
    var tint: Color
    var track: Color
    var height: CGFloat = 8

    private var clamped: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(height, proxy.size.width * clamped))
                    .opacity(fraction > 0 ? 1 : 0)
            }
        }
        .frame(height: height)
        .animation(.spring(duration: 0.6), value: clamped)
    }
}

/// Barra del presupuesto con color según el avance.
struct BudgetMeter: View {
    let ratio: Double
    var height: CGFloat = 12
    var track: Color = PinkPalette.onForest.opacity(0.14)

    var body: some View {
        PinkProgressBar(fraction: ratio, tint: BudgetTone(ratio: ratio).color, track: track, height: height)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Presupuesto consumido")
            .accessibilityValue(MoneyFormat.percent(min(max(ratio, 0), 9.99)))
    }
}
