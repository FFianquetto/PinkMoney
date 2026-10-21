import SwiftUI

/// Radiografía financiera con histórico: cada mes por separado o el año completo.
struct FinancialRadiographyView: View {
    @Environment(\.ledger) private var ledger
    @State private var period = HistoryPeriod(scope: .month)

    var body: some View {
        // Acción "Consultar Histórico Local": todo se calcula de la base local, una vez por render.
        let slices = ledger.slices(in: period)
        let count = ledger.items(in: period).count
        NavigationStack {
            PinkScreen {
                PinkScrollView {
                    PinkScreenHeader(
                        eyebrow: "Análisis de consumo",
                        title: "Radiografía",
                        subtitle: "Las áreas por donde se fuga tu dinero."
                    )

                    Picker("Periodo", selection: scopeBinding) {
                        ForEach(HistoryScope.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    PeriodNavigator(
                        period: period,
                        canGoBack: ledger.canGoBack(from: period),
                        canGoForward: ledger.canGoForward(from: period),
                        onBack: { move(-1) },
                        onForward: { move(1) }
                    )

                    PeriodSummaryCard(period: period, total: slices.total, count: count)

                    if period.scope == .year {
                        yearlySection
                    }

                    if let top = slices.first {
                        CategoryDonutCard(slices: slices)
                        TopLeakCard(slice: top)
                        breakdown(slices)
                    } else {
                        PinkCard {
                            EmptyStateView(
                                title: period.scope == .month ? "Sin gastos en este mes" : "Sin gastos en este año",
                                message: "Cuando registres gastos en este periodo, la dona se arma sola.",
                                mascotSize: 110
                            )
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var scopeBinding: Binding<HistoryScope> {
        Binding(
            get: { period.scope },
            set: { newScope in
                withAnimation(.snappy) { period = period.switching(to: newScope) }
            }
        )
    }

    private func move(_ value: Int) {
        withAnimation(.snappy) { period = period.shifted(by: value) }
    }

    // MARK: Secciones

    /// Vista anual: barras por mes y un renglón por cada mes con gastos.
    @ViewBuilder
    private var yearlySection: some View {
        let months = ledger.monthlyTotals(in: period)
        let withSpending = months.filter { $0.count > 0 }
        if !withSpending.isEmpty {
            MonthlyBarsCard(months: months)

            VStack(alignment: .leading, spacing: 12) {
                PinkSectionHeader("Mes por mes", eyebrow: "Toca un mes para ver su detalle")
                let peak = withSpending.map(\.total).max() ?? 0
                ForEach(withSpending.reversed()) { item in
                    MonthSummaryRow(item: item, maxTotal: peak) {
                        withAnimation(.snappy) {
                            period = HistoryPeriod(scope: .month, containing: item.month)
                        }
                    }
                }
            }
        }
    }

    private func breakdown(_ slices: [CategorySlice]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            PinkSectionHeader("Desglose de gastos hormiga", eyebrow: "Por categoría")
            ForEach(slices) { slice in
                CategoryBreakdownRow(slice: slice)
            }
        }
    }
}
