import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var mode: AuthMode = .login
    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorText: String?
    @FocusState private var focused: Field?

    private enum AuthMode: String, CaseIterable, Identifiable {
        case login = "Entrar"
        case register = "Registro"
        var id: String { rawValue }
    }

    private enum Field {
        case email
        case password
    }

    var body: some View {
        PinkScreen {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        CerdoMascot(size: 120)
                        Text("Bienvenido")
                            .font(PinkTheme.Font.title(.largeTitle))
                            .foregroundStyle(PinkPalette.ink)
                        Text("Ingresa tus credenciales para continuar.")
                            .font(.subheadline)
                            .foregroundStyle(PinkPalette.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 24)

                    Picker("Modo", selection: $mode) {
                        ForEach(AuthMode.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    PinkCard {
                        VStack(alignment: .leading, spacing: 16) {
                            PinkField(title: "Correo institucional", systemImage: "envelope") {
                                TextField("estudiante@uni.edu.mx", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.username)
                                    .autocorrectionDisabled()
                                    .focused($focused, equals: .email)
                                    .submitLabel(.next)
                                    .onSubmit { focused = .password }
                            }
                            PinkField(title: "Contraseña", systemImage: "lock") {
                                SecureField("••••••••", text: $password)
                                    .textContentType(mode == .register ? .newPassword : .password)
                                    .focused($focused, equals: .password)
                                    .submitLabel(.go)
                                    .onSubmit(submit)
                            }
                            if mode == .register {
                                Text("Mínimo 6 caracteres.")
                                    .font(.caption)
                                    .foregroundStyle(PinkPalette.inkSoft)
                            }
                            if let errorText {
                                StatusChip(error: errorText)
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        PrimaryDarkButton(
                            title: "Validar con Firebase",
                            systemImage: "lock.shield",
                            isLoading: isSubmitting,
                            action: submit
                        )
                        .disabled(isSubmitting || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)

                        PinkSoftButton(title: "Explorar sin cuenta", systemImage: "arrow.right.circle") {
                            auth.startLocalSession()
                        }
                    }

                    Text(footnote)
                        .font(.footnote)
                        .foregroundStyle(PinkPalette.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, PinkTheme.Spacing.screen)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var footnote: String {
        if PinkTheme.cloudSyncEnabled && FirebaseConfig.isConfigured {
            "La validación la hace Firebase. Los gastos viven primero en el iPhone."
        } else {
            "La nube está pendiente. Puedes explorar sin cuenta: todo se guarda en este iPhone."
        }
    }

    private func submit() {
        guard !isSubmitting, !email.isEmpty, !password.isEmpty else { return }
        focused = nil
        errorText = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                switch mode {
                case .login:
                    try await auth.login(email: email, password: password)
                case .register:
                    try await auth.register(email: email, password: password)
                }
            } catch {
                errorText = error.localizedDescription
            }
        }
    }
}
