import SwiftUI

/// Tarjeta principal del Dashboard: disponible, gasto de hoy y progreso del mes.
struct HeroBalanceCard: View {
    let ledger: Ledger

    private var isOver: Bool { ledger.remaining < 0 }

    var body: some View {
        PinkCard(style: .forest, padding: 22) {
            ZStack(alignment: .topTrailing) {
                decoration
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("PRESUPUESTO · \(MoneyFormat.monthTitle().uppercased())")
                            .pinkEyebrow(PinkPalette.rose, tracking: 1.1)
                        Spacer()
                        if ledger.budget > 0 {
                            PinkBadge(
                                text: "\(MoneyFormat.percent(min(ledger.ratio, 9.99))) consumido",
                                tint: BudgetTone(ratio: ledger.ratio).color
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isOver ? "Te pasaste por" : "Disponible")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(PinkPalette.onForest.opacity(0.9))
                        Text(MoneyFormat.currency(abs(ledger.remaining)))
                            .font(PinkTheme.Font.amountHero())
                            .foregroundStyle(isOver ? PinkPalette.danger : PinkPalette.onForest)
                            .contentTransition(.numericText())
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                    }

                    BudgetMeter(ratio: ledger.ratio)

                    HStack(alignment: .firstTextBaseline) {
                        stat("Hoy", value: ledger.todaySpent > 0 ? "−\(MoneyFormat.currency(ledger.todaySpent))" : MoneyFormat.currency(0), tint: PinkPalette.rose)
                        Spacer()
                        stat("Gastado", value: MoneyFormat.currency(ledger.monthSpent), trailing: true)
                        Spacer()
                        stat("Límite", value: MoneyFormat.currencyShort(ledger.budget), trailing: true)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var decoration: some View {
        ZStack {
            Circle()
                .stroke(PinkPalette.rose.opacity(0.10), lineWidth: 26)
                .frame(width: 150, height: 150)
                .offset(x: 62, y: -58)
            Circle()
                .fill(PinkPalette.rose.opacity(0.10))
                .frame(width: 90, height: 90)
                .offset(x: 14, y: -26)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func stat(_ title: String, value: String, tint: Color = PinkPalette.onForest, trailing: Bool = false) -> some View {
        VStack(alignment: trailing ? .trailing : .leading, spacing: 2) {
            Text(title.uppercased())
                .pinkEyebrow(PinkPalette.onForest.opacity(0.55), tracking: 0.8)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
