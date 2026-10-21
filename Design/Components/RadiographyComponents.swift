import Charts
import SwiftUI

/// Dona nativa con Swift Charts (`SectorMark`), total al centro y leyenda.
struct CategoryDonutCard: View {
    let slices: [CategorySlice]

    var body: some View {
        PinkCard {
            VStack(spacing: 16) {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Monto", slice.total),
                        innerRadius: .ratio(0.64),
                        angularInset: 2
                    )
                    .cornerRadius(7)
                    .foregroundStyle(slice.category.color)
                }
                .frame(height: 250)
                .chartLegend(.hidden)
                .overlay {
                    VStack(spacing: 2) {
                        Text("TOTAL").pinkEyebrow(PinkPalette.inkSoft)
                        Text(MoneyFormat.currency(slices.total))
                            .font(PinkTheme.Font.amount(.title3))
                            .foregroundStyle(PinkPalette.ink)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 54)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(summary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(slices) { slice in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(slice.category.color)
                                .frame(width: 9, height: 9)
                            Text(slice.category.title)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(PinkPalette.inkSoft)
                        }
                    }
                }
            }
        }
    }

    private var summary: String {
        guard let top = slices.first else { return "Gráfica de dona sin gastos" }
        return "Gráfica de dona. La categoría más alta es \(top.category.title), \(MoneyFormat.currency(top.total))."
    }
}

/// Tarjeta con la categoría que más dinero se lleva.
struct TopLeakCard: View {
    let slice: CategorySlice

    var body: some View {
        HStack(spacing: 14) {
            CategoryBadge(category: slice.category, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text("TU MAYOR FUGA").pinkEyebrow(tracking: 1)
                Text("\(slice.category.title) se lleva el \(MoneyFormat.percent(slice.percent))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PinkPalette.ink)
                Text("\(MoneyFormat.currency(slice.total)) en este periodo.")
                    .font(.footnote)
                    .foregroundStyle(PinkPalette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinkSurface(.rose, radius: PinkTheme.Radius.card)
        .accessibilityElement(children: .combine)
    }
}

/// Fila del desglose de gastos hormiga: categoría, monto, porcentaje y barra.
struct CategoryBreakdownRow: View {
    let slice: CategorySlice

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CategoryBadge(category: slice.category, size: 38)
                Text(slice.category.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PinkPalette.ink)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(MoneyFormat.currency(slice.total))
                        .font(PinkTheme.Font.amount(.subheadline))
                        .foregroundStyle(PinkPalette.ink)
                    Text(MoneyFormat.percent(slice.percent))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PinkPalette.inkSoft)
                }
            }
            PinkProgressBar(
                fraction: slice.percent,
                tint: slice.category.color,
                track: slice.category.color.opacity(0.16)
            )
        }
        .padding(16)
        .pinkSurface()
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Histórico por mes y año

/// Flechas para moverse entre meses o años, con el periodo en el centro.
struct PeriodNavigator: View {
    let period: HistoryPeriod
    let canGoBack: Bool
    let canGoForward: Bool
    let onBack: () -> Void
    let onForward: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            arrow("chevron.left", label: "Periodo anterior", enabled: canGoBack, action: onBack)
            VStack(spacing: 2) {
                Text(period.scope == .month ? "MES" : "AÑO COMPLETO").pinkEyebrow(PinkPalette.inkSoft, tracking: 1.2)
                Text(period.title())
                    .font(PinkTheme.Font.title(.title3))
                    .foregroundStyle(PinkPalette.ink)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            arrow("chevron.right", label: "Periodo siguiente", enabled: canGoForward, action: onForward)
        }
        .padding(10)
        .pinkSurface(.surface, radius: PinkTheme.Radius.card)
    }

    private func arrow(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline.weight(.bold))
                .foregroundStyle(enabled ? PinkPalette.accent : PinkPalette.inkFaint.opacity(0.4))
                .frame(width: 46, height: 46)
                .background(PinkPalette.surfaceMuted, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// Resumen del periodo: total gastado, número de movimientos y promedio.
struct PeriodSummaryCard: View {
    let period: HistoryPeriod
    let total: Double
    let count: Int

    var body: some View {
        PinkCard(style: .forest, padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(period.scope == .month ? "GASTADO EN EL MES" : "GASTADO EN EL AÑO")
                        .pinkEyebrow(PinkPalette.rose, tracking: 1.1)
                    Text(MoneyFormat.currency(total))
                        .font(PinkTheme.Font.amountHero())
                        .foregroundStyle(PinkPalette.onForest)
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .contentTransition(.numericText())
                }
                HStack(spacing: 12) {
                    stat(title: "Movimientos", value: "\(count)")
                    stat(title: period.scope == .month ? "Promedio diario" : "Promedio mensual", value: MoneyFormat.currency(average))
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var average: Double {
        total / Double(period.elapsedUnits())
    }

    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(PinkPalette.onForest.opacity(0.85))
            Text(value)
                .font(PinkTheme.Font.amount(.subheadline))
                .foregroundStyle(PinkPalette.onForest)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PinkPalette.onForest.opacity(0.10), in: RoundedRectangle(cornerRadius: PinkTheme.Radius.chip, style: .continuous))
    }
}

/// Barras con el gasto de cada mes del año.
struct MonthlyBarsCard: View {
    let months: [MonthTotal]

    var body: some View {
        PinkCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("GASTO POR MES").pinkEyebrow(PinkPalette.inkSoft, tracking: 1.1)
                Chart(months) { item in
                    BarMark(
                        x: .value("Mes", item.month, unit: .month),
                        y: .value("Gasto", item.total)
                    )
                    .cornerRadius(5)
                    .foregroundStyle(item.total == peak ? PinkPalette.accent : PinkPalette.accent.opacity(0.45))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.narrow).locale(MoneyFormat.locale))
                            .foregroundStyle(PinkPalette.inkSoft)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine().foregroundStyle(PinkPalette.hairline)
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(amount.formatted(.number.notation(.compactName).locale(MoneyFormat.locale)))
                                    .foregroundStyle(PinkPalette.inkSoft)
                            }
                        }
                    }
                }
                .frame(height: 190)
                .accessibilityLabel("Gráfica de barras con el gasto de cada mes")
            }
        }
    }

    private var peak: Double { months.map(\.total).max() ?? 0 }
}

/// Renglón de un mes dentro del año: toca para abrir ese mes.
struct MonthSummaryRow: View {
    let item: MonthTotal
    let maxTotal: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(MoneyFormat.capitalizedFirst(item.month.formatted(.dateTime.month(.wide).locale(MoneyFormat.locale))))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PinkPalette.ink)
                        Text(item.count == 1 ? "1 movimiento" : "\(item.count) movimientos")
                            .font(.caption)
                            .foregroundStyle(PinkPalette.inkSoft)
                    }
                    Spacer()
                    Text(MoneyFormat.currency(item.total))
                        .font(PinkTheme.Font.amount(.subheadline))
                        .foregroundStyle(PinkPalette.ink)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PinkPalette.inkFaint)
                }
                PinkProgressBar(
                    fraction: maxTotal > 0 ? item.total / maxTotal : 0,
                    tint: PinkPalette.accent,
                    track: PinkPalette.accent.opacity(0.16)
                )
            }
            .padding(16)
            .pinkSurface()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre el detalle de este mes")
    }
}
