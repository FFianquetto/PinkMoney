import SwiftUI
import UIKit

struct NewExpenseSheet: View {
    /// Se llama cuando el gasto quedó guardado, justo antes de cerrar el modal.
    var onSaved: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var network: NetworkMonitor
    @EnvironmentObject private var store: LedgerStore
    @EnvironmentObject private var sync: SyncManager
    @StateObject private var viewModel = ExpenseViewModel()
    @FocusState private var focused: Field?

    private enum Field {
        case amount
        case note
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    private let quickAmounts: [Double] = [20, 50, 100, 200]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: PinkTheme.Spacing.section) {
                    amountCard
                    categorySection
                    PinkField(title: "Nota (opcional)", systemImage: "text.alignleft") {
                        TextField("Ej. tortas de la facultad", text: $viewModel.note, axis: .vertical)
                            .lineLimit(1...3)
                            .focused($focused, equals: .note)
                    }

                    Label(queueCaption.text, systemImage: queueCaption.icon)
                        .font(.footnote)
                        .foregroundStyle(PinkPalette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage = viewModel.errorMessage {
                        StatusChip(error: errorMessage)
                    }

                    PrimaryDarkButton(
                        title: "Guardar gasto",
                        systemImage: "checkmark.circle.fill",
                        action: save
                    )
                }
                .padding(PinkTheme.Spacing.screen)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PinkPalette.canvas)
            .navigationTitle("Nuevo registro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Regresar") { dismiss() }
                        .foregroundStyle(PinkPalette.accent)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { focused = nil }
                }
            }
        }
        .onAppear { focused = .amount }
    }

    // MARK: Secciones

    private var amountCard: some View {
        PinkCard(style: .forest, padding: 22) {
            VStack(spacing: 14) {
                Text("MONTO").pinkEyebrow(PinkPalette.rose, tracking: 1.4)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("$")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(PinkPalette.rose)
                    TextField("0", text: $viewModel.amountText)
                        .groupedMoney($viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundStyle(PinkPalette.onForest)
                        .multilineTextAlignment(.center)
                        .focused($focused, equals: .amount)
                        .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { value in
                        PinkPillButton(title: MoneyFormat.currencyShort(value), tone: .onForest) {
                            viewModel.amountText = MoneyFormat.editable(value)
                        }
                    }
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PinkSectionHeader("Categoría", eyebrow: "¿En qué fue?")
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(ExpenseCategory.allCases) { category in
                    CategoryPill(category: category, isSelected: viewModel.category == category) {
                        viewModel.category = category
                    }
                }
            }
        }
    }

    private var queueCaption: (text: String, icon: String) {
        guard PinkTheme.cloudSyncEnabled else {
            return ("Se guarda en la base de datos de este iPhone.", "iphone")
        }
        if !network.isConnected {
            return ("Sin internet. Se guarda en el iPhone y entra a la cola de espera.", "tray.full")
        }
        if auth.canSyncToCloud {
            return ("Se guarda en el iPhone y se sube a Firestore.", "icloud.and.arrow.up")
        }
        return ("Se guarda en el iPhone. La sincronización en la nube está pendiente.", "iphone")
    }

    /// Flujo del diagrama: guardar local → actualizar saldo → validar red → cerrar el modal.
    private func save() {
        focused = nil
        guard viewModel.save(to: store, sync: sync) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved()
        dismiss()
    }
}

// MARK: - Presentación reutilizable

private struct NewExpenseSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onSaved: () -> Void
    @State private var detent: PresentationDetent = .large

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            NewExpenseSheet(onSaved: onSaved)
                .presentationDetents([.medium, .large], selection: $detent)
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(32)
                .presentationBackground(PinkPalette.canvas)
        }
    }
}

extension View {
    /// Modal "Nuevo Registro" con `.presentationDetents`. Se usa desde Inicio y desde la barra inferior.
    func newExpenseSheet(isPresented: Binding<Bool>, onSaved: @escaping () -> Void = {}) -> some View {
        modifier(NewExpenseSheetModifier(isPresented: isPresented, onSaved: onSaved))
    }
}
