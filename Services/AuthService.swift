import Combine
import CryptoKit
import Foundation
import SwiftData

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var isSessionActive = false
    @Published private(set) var currentUser: ProfileSnapshot?
    @Published private(set) var statusMessage: String?

    var afterAuthentication: (@MainActor () async -> Void)?

    private let container: ModelContainer
    private let gateway: FirebaseGateway
    private let network: NetworkMonitor
    private let ledger: LedgerStore
    private var session: PersistedSession?
    private let budgetDirtyKey = "pinkmoney.budget.dirty"

    init(container: ModelContainer, gateway: FirebaseGateway, network: NetworkMonitor, ledger: LedgerStore) {
        self.container = container
        self.gateway = gateway
        self.network = network
        self.ledger = ledger
    }

    /// La nube solo se usa si está habilitada en `PinkTheme` y Firebase está configurado.
    private var cloudEnabled: Bool {
        PinkTheme.cloudSyncEnabled && FirebaseConfig.isConfigured
    }

    var canSyncToCloud: Bool {
        cloudEnabled && session?.usesCloud == true
    }

    var isBudgetDirty: Bool {
        UserDefaults.standard.bool(forKey: budgetDirtyKey)
    }

    func login(email: String, password: String) async throws {
        let clean = try validate(email: email, password: password)
        if cloudEnabled {
            guard network.isConnected else { throw PinkMoneyError.offline }
            let cloud = try await gateway.signIn(email: clean, password: password)
            try await adopt(cloud)
        } else {
            guard let credential = SessionVault.credential(email: clean) else {
                throw PinkMoneyError.firebase("No hay una cuenta con ese correo en este iPhone.")
            }
            let hash = PasswordHasher.hash(password: password, salt: credential.salt)
            guard hash == credential.passwordHash else {
                throw PinkMoneyError.firebase("Correo o contraseña incorrectos.")
            }
            try await adopt(localSession(uid: credential.uid, email: clean))
        }
    }

    func register(email: String, password: String) async throws {
        let clean = try validate(email: email, password: password)
        if cloudEnabled {
            guard network.isConnected else { throw PinkMoneyError.offline }
            let cloud = try await gateway.signUp(email: clean, password: password)
            try await adopt(cloud)
        } else {
            guard SessionVault.credential(email: clean) == nil else {
                throw PinkMoneyError.firebase("Ese correo ya tiene cuenta. Inicia sesión.")
            }
            let salt = PasswordHasher.salt()
            let stored = LocalCredential(
                email: clean,
                uid: UUID().uuidString,
                salt: salt,
                passwordHash: PasswordHasher.hash(password: password, salt: salt)
            )
            try SessionVault.saveCredential(stored)
            try await adopt(localSession(uid: stored.uid, email: clean))
        }
    }

    func logout() {
        do {
            let context = container.mainContext
            try SwiftDataExpenseRepository(context: context).deleteAll()
            try SwiftDataUserRepository(context: context).deleteAll()
        } catch {
            statusMessage = error.localizedDescription
            return
        }
        SessionVault.deleteSession()
        session = nil
        currentUser = nil
        UserDefaults.standard.set(false, forKey: budgetDirtyKey)
        isSessionActive = false
        ledger.reload()
        if !PinkTheme.requiresLogin {
            startLocalSession()
        }
    }

    // MARK: Modo local (backend pendiente)

    static let localUserID = "local-student"
    static let localEmail = "estudiante@pinkmoney.local"

    /// `true` cuando se navega sin cuenta en la nube.
    var isLocalMode: Bool {
        currentUser?.id == Self.localUserID
    }

    /// Abre una sesión local para navegar libremente mientras Firebase queda pendiente.
    /// Reutiliza el perfil local si existe y conserva los gastos guardados.
    func startLocalSession() {
        do {
            let users = SwiftDataUserRepository(context: container.mainContext)
            let profile: UserProfile
            if let existing = try users.current() {
                profile = existing
            } else {
                profile = try users.upsert(
                    id: Self.localUserID,
                    email: Self.localEmail,
                    budget: nil,
                    sessionToken: nil
                )
            }
            session = nil
            currentUser = ProfileSnapshot(
                id: profile.id,
                email: profile.email,
                monthlyBudget: profile.monthlyBudget,
                sessionToken: nil,
                usesCloud: false,
                displayName: profile.displayName,
                school: profile.school
            )
            isSessionActive = true
            ledger.reload()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func clearStatus() {
        statusMessage = nil
    }

    func restoreSession() async {
        guard let stored = SessionVault.loadSession() else { return }
        var active = stored
        if stored.usesCloud && cloudEnabled && stored.expiration < Date().addingTimeInterval(90) && network.isConnected {
            do {
                active = try await gateway.refresh(stored)
                try SessionVault.saveSession(active)
            } catch PinkMoneyError.network {
                active = stored
            } catch {
                SessionVault.deleteSession()
                session = nil
                return
            }
        }
        do {
            try installProfile(session: active, preferredBudget: nil)
        } catch {
            SessionVault.deleteSession()
            session = nil
            currentUser = nil
            return
        }
        await afterAuthentication?()
        isSessionActive = true
    }

    func updateMonthlyBudget(_ amount: Double) throws {
        guard amount > 0, amount <= 1_000_000 else { throw PinkMoneyError.invalidBudget }
        guard let userID = currentUser?.id else {
            throw PinkMoneyError.localStore("No hay una sesión para guardar el presupuesto.")
        }
        try SwiftDataUserRepository(context: container.mainContext).updateBudget(userID: userID, amount: amount)
        UserDefaults.standard.set(true, forKey: budgetDirtyKey)
        if var currentUser {
            currentUser.monthlyBudget = amount
            self.currentUser = currentUser
        }
        ledger.reload()
    }

    /// Guarda nombre, escuela y (solo en modo local) el correo del perfil. Todo queda en la base del iPhone.
    func updateProfile(displayName: String, school: String, email: String) throws {
        guard let userID = currentUser?.id else {
            throw PinkMoneyError.localStore("No hay una sesión para guardar el perfil.")
        }
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 40 else { throw PinkMoneyError.invalidName }
        let schoolName = school.trimmingCharacters(in: .whitespacesAndNewlines)
        guard schoolName.count <= 60 else { throw PinkMoneyError.invalidSchool }

        var newEmail: String?
        if isLocalMode {
            let clean = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let predicate = NSPredicate(
                format: "SELF MATCHES[c] %@",
                "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            )
            guard predicate.evaluate(with: clean) else { throw PinkMoneyError.invalidEmail }
            newEmail = clean
        }

        try SwiftDataUserRepository(context: container.mainContext)
            .updateDetails(userID: userID, displayName: name, school: schoolName, email: newEmail)
        if var currentUser {
            currentUser.displayName = name
            currentUser.school = schoolName
            if let newEmail { currentUser.email = newEmail }
            self.currentUser = currentUser
        }
    }

    func applyRemoteBudget(_ amount: Double) throws {
        guard let userID = currentUser?.id else { return }
        try SwiftDataUserRepository(context: container.mainContext).updateBudget(userID: userID, amount: amount)
        if var currentUser {
            currentUser.monthlyBudget = amount
            self.currentUser = currentUser
        }
        ledger.reload()
    }

    func clearBudgetDirty() {
        UserDefaults.standard.set(false, forKey: budgetDirtyKey)
    }

    func validToken(forceRefresh: Bool = false) async throws -> String {
        guard var session, session.usesCloud else { throw PinkMoneyError.unauthorized }
        let stillFresh = !forceRefresh && session.expiration > Date().addingTimeInterval(90)
        if !stillFresh {
            let refreshed = try await gateway.refresh(session)
            try SessionVault.saveSession(refreshed)
            self.session = refreshed
            if var currentUser {
                currentUser.sessionToken = refreshed.idToken
                self.currentUser = currentUser
            }
            try? SwiftDataUserRepository(context: container.mainContext)
                .updateSessionToken(userID: refreshed.uid, token: refreshed.idToken)
            session = refreshed
        }
        return session.idToken
    }

    private func adopt(_ newSession: PersistedSession) async throws {
        do {
            try SessionVault.saveSession(newSession)
            try installProfile(session: newSession, preferredBudget: nil)
        } catch {
            SessionVault.deleteSession()
            session = nil
            currentUser = nil
            throw error
        }
        await afterAuthentication?()
        isSessionActive = true
    }

    private func installProfile(session: PersistedSession, preferredBudget: Double?) throws {
        let users = SwiftDataUserRepository(context: container.mainContext)
        if let existing = try users.current(), existing.id != session.uid {
            try SwiftDataExpenseRepository(context: container.mainContext).deleteAll()
            try users.deleteAll()
        }
        let profile = try users.upsert(
            id: session.uid,
            email: session.email,
            budget: preferredBudget,
            sessionToken: session.idToken
        )
        self.session = session
        currentUser = ProfileSnapshot(
            id: profile.id,
            email: profile.email,
            monthlyBudget: profile.monthlyBudget,
            sessionToken: profile.sessionToken,
            usesCloud: session.usesCloud,
            displayName: profile.displayName,
            school: profile.school
        )
        ledger.reload()
    }

    private func localSession(uid: String, email: String) -> PersistedSession {
        PersistedSession(
            uid: uid,
            email: email,
            idToken: UUID().uuidString,
            refreshToken: "",
            expiration: .distantFuture,
            usesCloud: false
        )
    }

    private func validate(email: String, password: String) throws -> String {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let predicate = NSPredicate(
            format: "SELF MATCHES[c] %@",
            "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        )
        guard predicate.evaluate(with: clean) else { throw PinkMoneyError.invalidEmail }
        guard password.count >= 6 else { throw PinkMoneyError.weakPassword }
        return clean
    }
}

private enum PasswordHasher {
    static func salt() -> String {
        UUID().uuidString
    }

    static func hash(password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data("\(salt):\(password)".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
