import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var sync: SyncManager

    // Presupuesto
    @State private var budgetText = ""
    @State private var budgetFeedback: PinkFeedback?
    @State private var isSavingBudget = false

    // Datos del perfil
    @State private var nameText = ""
    @State private var schoolText = ""
    @State private var emailText = ""
    @State private var detailsFeedback: PinkFeedback?

    @State private var confirmLogout = false
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case school
        case email
        case budget
    }

    private var currentBudget: Double {
        auth.currentUser?.monthlyBudget ?? PinkTheme.defaultBudget
    }

    private var displayedName: String {
        let name = auth.currentUser?.displayName ?? ""
        return name.isEmpty ? "Estudiante activo" : name
    }

    var body: some View {
        NavigationStack {
            PinkScreen {
                PinkScrollView {
                    header
                    detailsSection
                    budgetSection
                    cloudSection
                    sessionSection
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") { focusedField = nil }
                }
            }
            .onAppear {
                syncFieldWithBudget()
                loadDetails()
            }
            // Si los datos cambian desde otro lugar (limpiar datos, nube), los campos lo reflejan.
            .onChange(of: auth.currentUser?.monthlyBudget) { _, _ in
                if focusedField != .budget { syncFieldWithBudget() }
            }
            .onChange(of: auth.currentUser?.id) { _, _ in
                loadDetails()
                syncFieldWithBudget()
            }
            .confirmationDialog("¿Cerrar sesión?", isPresented: $confirmLogout, titleVisibility: .visible) {
                Button("Cerrar sesión y limpiar datos", role: .destructive) {
                    notifications.resetBudgetAlerts()
                    budgetFeedback = nil
                    detailsFeedback = nil
                    auth.logout()
                    syncFieldWithBudget()
                    loadDetails()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Se limpia la base de datos local de este dispositivo. Tus gastos guardados aquí se eliminan.")
            }
            .alert("No se pudo cerrar sesión", isPresented: logoutAlert) {
                Button("Entendido", role: .cancel) { auth.clearStatus() }
            } message: {
                Text(auth.statusMessage ?? "")
            }
        }
    }

    private var logoutAlert: Binding<Bool> {
        Binding(
            get: { auth.statusMessage != nil },
            set: { isPresented in
                if !isPresented { auth.clearStatus() }
            }
        )
    }

    // MARK: Secciones

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            PinkScreenHeader(eyebrow: "Ajuste dinámico", title: "Configuración")

            PinkCard(style: .forest) {
                HStack(spacing: 16) {
                    CerdoMascot(size: 84)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(displayedName)
                            .font(PinkTheme.Font.title(.title3))
                            .foregroundStyle(PinkPalette.onForest)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(headerSubtitle)
                            .font(.footnote)
                            .foregroundStyle(PinkPalette.onForest.opacity(0.9))
                            .lineLimit(2)
                        PinkBadge(
                            text: auth.isLocalMode ? "Modo local" : "Sesión iniciada",
                            systemImage: auth.isLocalMode ? "iphone" : "checkmark.seal.fill",
                            tint: PinkPalette.rose
                        )
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var headerSubtitle: String {
        let school = auth.currentUser?.school ?? ""
        if !school.isEmpty { return school }
        return auth.isLocalMode ? "Sesión local en este iPhone" : (auth.currentUser?.email ?? "Sesión iniciada")
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PinkSectionHeader("Mis datos", eyebrow: "Perfil")
            PinkCard {
                VStack(alignment: .leading, spacing: 16) {
                    PinkField(title: "Nombre", systemImage: "person.fill") {
                        TextField("Tu nombre", text: $nameText)
                            .textContentType(.name)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .name)
                            .onSubmit { focusedField = .school }
                    }

                    PinkField(title: "Escuela o facultad", systemImage: "graduationcap.fill") {
                        TextField("Ej. FIME, UANL", text: $schoolText)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .school)
                            .onSubmit { focusedField = auth.isLocalMode ? .email : nil }
                    }

                    PinkField(title: "Correo", systemImage: "envelope.fill") {
                        TextField("correo@ejemplo.com", text: $emailText)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .focused($focusedField, equals: .email)
                            .disabled(!auth.isLocalMode)
                            .opacity(auth.isLocalMode ? 1 : 0.7)
                            .onSubmit { focusedField = nil }
                    }

                    if !auth.isLocalMode {
                        Text("El correo de una cuenta en la nube no se puede cambiar desde aquí.")
                            .font(.footnote)
                            .foregroundStyle(PinkPalette.inkSoft)
                    }

                    if let detailsFeedback {
                        StatusChip(feedback: detailsFeedback)
                    }

                    PrimaryDarkButton(
                        title: "Guardar datos",
                        systemImage: "checkmark",
                        action: saveDetails
                    )
                }
            }
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PinkSectionHeader("Presupuesto", eyebrow: "Límite mensual")
            PinkCard {
                VStack(alignment: .leading, spacing: 16) {
                    PinkField(title: "Límite mensual", systemImage: "banknote") {
                        HStack(spacing: 4) {
                            Text("$")
                                .font(PinkTheme.Font.title(.title2))
                                .foregroundStyle(PinkPalette.inkSoft)
                            TextField("8,000", text: $budgetText)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .budget)
                                .groupedMoney($budgetText)
                                .font(PinkTheme.Font.title(.title2))
                        }
                    }

                    HStack(spacing: 10) {
                        PinkPillButton(title: "− $500") { adjustBudget(by: -500) }
                        PinkPillButton(title: "+ $500") { adjustBudget(by: 500) }
                    }

                    if let budgetFeedback {
                        StatusChip(feedback: budgetFeedback)
                    }

                    PrimaryDarkButton(
                        title: "Guardar presupuesto",
                        systemImage: "checkmark",
                        isLoading: isSavingBudget,
                        action: saveBudget
                    )
                }
            }
        }
    }

    private var cloudSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PinkSectionHeader("Sincronización", eyebrow: "Nube")
            PinkIconRow(
                systemImage: auth.canSyncToCloud ? "checkmark.icloud.fill" : "icloud.slash",
                title: cloudTitle,
                message: cloudCopy,
                tint: auth.canSyncToCloud ? PinkPalette.success : PinkPalette.sageDeep,
                iconBackground: PinkPalette.surfaceMuted
            )
        }
    }

    private var sessionSection: some View {
        VStack(spacing: 12) {
            Button {
                confirmLogout = true
            } label: {
                Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(PinkSoftButtonStyle(tint: PinkPalette.danger))

            Text("Pink Money · versión 1.0")
                .font(.caption)
                .foregroundStyle(PinkPalette.inkFaint)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Textos

    private var cloudTitle: String {
        if auth.canSyncToCloud { return "Firebase conectado" }
        return auth.isLocalMode ? "Nube pendiente" : "Cola local"
    }

    private var cloudCopy: String {
        if auth.canSyncToCloud {
            return "Los gastos pendientes se suben a Firestore en cuanto hay internet."
        }
        if auth.isLocalMode || !PinkTheme.cloudSyncEnabled {
            return "Todo se guarda en este iPhone. Cuando conectemos el backend, la cola de espera se sincroniza sola."
        }
        if FirebaseConfig.isConfigured {
            return "Esta sesión es local. Entra con Firebase para subir la cola."
        }
        return "Agrega API_KEY y PROJECT_ID en FirebaseConfig para sincronizar con Firestore."
    }

    // MARK: Acciones

    private func loadDetails() {
        nameText = auth.currentUser?.displayName ?? ""
        schoolText = auth.currentUser?.school ?? ""
        emailText = auth.currentUser?.email ?? ""
    }

    private func saveDetails() {
        focusedField = nil
        do {
            try auth.updateProfile(displayName: nameText, school: schoolText, email: emailText)
            loadDetails()
            detailsFeedback = .success("Datos actualizados.")
        } catch {
            detailsFeedback = .failure(error)
        }
    }

    private func syncFieldWithBudget() {
        budgetText = MoneyFormat.editable(currentBudget)
    }

    private func adjustBudget(by delta: Double) {
        let base = MoneyFormat.parse(budgetText) ?? currentBudget
        budgetText = MoneyFormat.editable(min(max(500, base + delta), MoneyFormat.maxAmount))
        budgetFeedback = nil
    }

    private func saveBudget() {
        guard let amount = MoneyFormat.parse(budgetText) else {
            budgetFeedback = .failure(PinkMoneyError.invalidBudget)
            return
        }
        isSavingBudget = true
        budgetFeedback = nil
        Task {
            defer { isSavingBudget = false }
            do {
                try auth.updateMonthlyBudget(amount)
                await sync.syncPending()
                budgetText = MoneyFormat.editable(amount)
                focusedField = nil
                budgetFeedback = .success("Presupuesto actualizado.")
            } catch {
                budgetFeedback = .failure(error)
            }
        }
    }
}
