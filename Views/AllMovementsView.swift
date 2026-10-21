import SwiftUI

/// Historial completo agrupado por día, con filtro por categoría y borrado con swipe.
struct AllMovementsView: View {
    @Environment(\.ledger) private var ledger
    @Environment(\.barClearance) private var barClearance
    @EnvironmentObject private var store: LedgerStore
    @State private var filter: ExpenseCategory?
    @State private var errorText: String?

    var body: some View {
        let groups = ledger.groups(category: filter)
        PinkScreen {
            List {
                Section {
                    CategoryFilterBar(selection: $filter)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if let errorText {
                    StatusChip(error: errorText)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if groups.isEmpty {
                    PinkCard {
                        EmptyStateView(
                            title: filter.map { "Nada en \($0.title)" } ?? "Sin movimientos",
                            message: "Cuando registres gastos aparecerán agrupados por día."
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(groups) { group in
                        Section {
                            ForEach(group.items) { movement in
                                MovementRow(movement: movement)
                                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            delete(movement)
                                        } label: {
                                            Label("Borrar", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            dayHeader(group)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .contentMargins(.horizontal, PinkTheme.Spacing.screen, for: .scrollContent)
            .contentMargins(.bottom, 16 + barClearance, for: .scrollContent)
        }
        .navigationTitle("Movimientos")
        .navigationBarTitleDisplayMode(.large)
    }

    private func dayHeader(_ group: MovementDayGroup) -> some View {
        HStack {
            Text(MoneyFormat.dayTitle(group.day))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PinkPalette.ink)
            Spacer()
            Text("−\(MoneyFormat.currency(group.total))")
                .font(PinkTheme.Font.amount(.footnote))
                .foregroundStyle(PinkPalette.inkSoft)
        }
        .textCase(nil)
        .padding(.top, 6)
    }

    private func delete(_ movement: MovementItem) {
        do {
            try store.delete(id: movement.id)
            errorText = nil
        } catch {
            errorText = error.localizedDescription
        }
    }
}
