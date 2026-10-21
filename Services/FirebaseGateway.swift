import Foundation
import os

struct FirebaseGateway: Sendable {
    private let session: URLSession
    private let logger = Logger(subsystem: "com.pinkmoney.app", category: "firebase")

    init(session: URLSession = .shared) {
        self.session = session
    }

    func signIn(email: String, password: String) async throws -> PersistedSession {
        try await identity(method: "signInWithPassword", email: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> PersistedSession {
        try await identity(method: "signUp", email: email, password: password)
    }

    func refresh(_ session: PersistedSession) async throws -> PersistedSession {
        try requireConfig()
        guard var components = URLComponents(string: "https://securetoken.googleapis.com/v1/token") else {
            throw PinkMoneyError.firebase("La URL de renovación no es válida.")
        }
        components.queryItems = [URLQueryItem(name: "key", value: FirebaseConfig.apiKey)]
        guard let url = components.url else {
            throw PinkMoneyError.firebase("La URL de renovación no es válida.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let encoded = session.refreshToken.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? session.refreshToken
        request.httpBody = Data("grant_type=refresh_token&refresh_token=\(encoded)".utf8)

        let data = try await execute(request)
        let decoded: RefreshResponse
        do {
            decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        } catch {
            throw PinkMoneyError.firebase("Firebase no devolvió un token usable.")
        }
        let seconds = TimeInterval(decoded.expires_in) ?? 3600
        return PersistedSession(
            uid: decoded.user_id,
            email: session.email,
            idToken: decoded.id_token,
            refreshToken: decoded.refresh_token,
            expiration: Date().addingTimeInterval(seconds),
            usesCloud: true
        )
    }

    func upsertExpense(_ expense: ExpensePayload, uid: String, token: String) async throws {
        try await upsertDocument(
            path: "users/\(uid)/expenses/\(expense.id.uuidString)",
            fields: expenseFields(expense),
            token: token
        )
    }

    func upsertUser(uid: String, email: String, monthlyBudget: Double, token: String) async throws {
        try await upsertDocument(
            path: "users/\(uid)",
            fields: [
                "email": .string(email),
                "monthlyBudget": .double(monthlyBudget)
            ],
            token: token
        )
    }

    func fetchUser(uid: String, token: String) async throws -> RemoteProfile? {
        let url = try documentURL(path: "users/\(uid)", query: [])
        do {
            let data = try await send(url: url, method: "GET", body: nil, token: token)
            let document = try JSONDecoder().decode(FSDocument.self, from: data)
            let fields = document.fields ?? [:]
            return RemoteProfile(
                email: fields["email"]?.stringValue,
                monthlyBudget: fields["monthlyBudget"]?.number
            )
        } catch PinkMoneyError.missingDocument {
            return nil
        }
    }

    func fetchExpenses(uid: String, token: String) async throws -> [ExpensePayload] {
        var pageToken: String?
        var results: [ExpensePayload] = []

        repeat {
            var query = [URLQueryItem(name: "pageSize", value: "100")]
            if let pageToken {
                query.append(URLQueryItem(name: "pageToken", value: pageToken))
            }
            let url = try documentURL(path: "users/\(uid)/expenses", query: query)
            let data: Data
            do {
                data = try await send(url: url, method: "GET", body: nil, token: token)
            } catch PinkMoneyError.missingDocument {
                return results
            }
            let page = try JSONDecoder().decode(FSList.self, from: data)
            results.append(contentsOf: (page.documents ?? []).compactMap(Self.payload(from:)))
            pageToken = page.nextPageToken
        } while pageToken != nil && results.count < 2_000

        return results
    }

    private func identity(method: String, email: String, password: String) async throws -> PersistedSession {
        let url = try identityURL(method)
        let body = IdentityRequest(email: email, password: password, returnSecureToken: true)
        let data = try await send(url: url, method: "POST", body: body, token: nil)
        let decoded: IdentityResponse
        do {
            decoded = try JSONDecoder().decode(IdentityResponse.self, from: data)
        } catch {
            throw PinkMoneyError.firebase("Firebase no devolvió la sesión.")
        }
        let seconds = TimeInterval(decoded.expiresIn) ?? 3600
        return PersistedSession(
            uid: decoded.localId,
            email: decoded.email,
            idToken: decoded.idToken,
            refreshToken: decoded.refreshToken,
            expiration: Date().addingTimeInterval(seconds),
            usesCloud: true
        )
    }

    private func upsertDocument(path: String, fields: [String: FSValue], token: String) async throws {
        let patchURL = try documentURL(
            path: path,
            query: fields.keys.sorted().map { URLQueryItem(name: "updateMask.fieldPaths", value: $0) }
                + [URLQueryItem(name: "allowMissing", value: "true")]
        )
        do {
            _ = try await send(url: patchURL, method: "PATCH", body: FSBody(fields: fields), token: token)
        } catch PinkMoneyError.missingDocument {
            let parts = path.split(separator: "/").map(String.init)
            let parent = parts.dropLast().joined(separator: "/")
            let documentID = parts.last ?? UUID().uuidString
            let createURL = try documentURL(
                path: parent,
                query: [URLQueryItem(name: "documentId", value: documentID)]
            )
            _ = try await send(url: createURL, method: "POST", body: FSBody(fields: fields), token: token)
        }
    }

    private func expenseFields(_ expense: ExpensePayload) -> [String: FSValue] {
        var fields: [String: FSValue] = [
            "amount": .double(expense.amount),
            "category": .string(expense.category),
            "date": .timestamp(Self.timestampString(expense.date)),
            "isSynced": .bool(expense.isSynced)
        ]
        if let note = expense.note, !note.isEmpty {
            fields["note"] = .string(note)
        }
        return fields
    }

    private func identityURL(_ method: String) throws -> URL {
        try requireConfig()
        guard var components = URLComponents(string: "https://identitytoolkit.googleapis.com/v1/accounts:\(method)") else {
            throw PinkMoneyError.firebase("La URL de Auth no es válida.")
        }
        components.queryItems = [URLQueryItem(name: "key", value: FirebaseConfig.apiKey)]
        guard let url = components.url else {
            throw PinkMoneyError.firebase("La URL de Auth no es válida.")
        }
        return url
    }

    private func documentURL(path: String, query: [URLQueryItem]) throws -> URL {
        try requireConfig()
        let project = FirebaseConfig.projectID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? FirebaseConfig.projectID
        guard var components = URLComponents(string: "https://firestore.googleapis.com/v1/projects/\(project)/databases/(default)/documents") else {
            throw PinkMoneyError.firebase("La URL de Firestore no es válida.")
        }
        let suffix = path.split(separator: "/").map { segment -> String in
            String(segment).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
        }.joined(separator: "/")
        if !suffix.isEmpty {
            components.path += "/" + suffix
        }
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else {
            throw PinkMoneyError.firebase("La URL de Firestore no es válida.")
        }
        return url
    }

    private func requireConfig() throws {
        guard FirebaseConfig.isConfigured else {
            throw PinkMoneyError.firebase("Faltan la API key y el project ID de Firebase.")
        }
    }

    private func send(url: URL, method: String, body: (any Encodable)?, token: String?) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        return try await execute(request)
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            logger.error("Red Firebase: \(error.code.rawValue, privacy: .public)")
            throw PinkMoneyError.network
        } catch let error as PinkMoneyError {
            throw error
        } catch {
            throw PinkMoneyError.network
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        if status == 404 {
            throw PinkMoneyError.missingDocument
        }
        guard (200...299).contains(status) else {
            let mapped = describe(data, status: status)
            logger.error("Firebase HTTP \(status, privacy: .public)")
            throw mapped
        }
        return data
    }

    private func describe(_ data: Data, status: Int) -> PinkMoneyError {
        if let envelope = try? JSONDecoder().decode(FirebaseErrorEnvelope.self, from: data) {
            return map(envelope.error.message, status: status)
        }
        if let oauth = try? JSONDecoder().decode(OAuthError.self, from: data) {
            return map(oauth.error ?? oauth.error_description ?? "", status: status)
        }
        if status == 401 || status == 403 {
            return .unauthorized
        }
        return .firebase("Firebase respondió con un error (\(status)).")
    }

    private func map(_ raw: String, status: Int) -> PinkMoneyError {
        let code = raw.split(separator: ":", maxSplits: 1).first
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? raw
        switch code {
        case "EMAIL_EXISTS":
            return .firebase("Ese correo ya tiene cuenta. Inicia sesión.")
        case "EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS":
            return .firebase("Correo o contraseña incorrectos.")
        case "WEAK_PASSWORD":
            return .weakPassword
        case "INVALID_EMAIL":
            return .invalidEmail
        case "TOO_MANY_ATTEMPTS_TRY_LATER":
            return .firebase("Demasiados intentos. Espera un momento y vuelve a entrar.")
        case "INVALID_REFRESH_TOKEN", "TOKEN_EXPIRED", "invalid_grant", "USER_DISABLED":
            return .unauthorized
        default:
            if status == 401 || status == 403 { return .unauthorized }
            return .firebase("No se pudo completar la validación con Firebase.")
        }
    }

    private static func payload(from document: FSDocument) -> ExpensePayload? {
        guard let idString = document.name.split(separator: "/").last.map(String.init),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        let fields = document.fields ?? [:]
        guard let amount = fields["amount"]?.number else { return nil }
        let category = fields["category"]?.stringValue ?? ExpenseCategory.despensa.rawValue
        let date = fields["date"]?.timestampValue.flatMap(parseDate) ?? .now
        let note = fields["note"]?.stringValue
        let synced = fields["isSynced"]?.booleanValue ?? true
        return ExpensePayload(
            id: id,
            amount: amount,
            category: category,
            date: date,
            note: note,
            isSynced: synced
        )
    }

    private static func timestampString(_ date: Date) -> String {
        fractionalFormatter.string(from: date)
    }

    private static func parseDate(_ value: String) -> Date? {
        fractionalFormatter.date(from: value) ?? plainFormatter.date(from: value)
    }

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plainFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

struct RemoteProfile: Sendable {
    var email: String?
    var monthlyBudget: Double?
}

private struct IdentityRequest: Encodable {
    var email: String
    var password: String
    var returnSecureToken: Bool
}

private struct IdentityResponse: Decodable {
    var idToken: String
    var email: String
    var refreshToken: String
    var expiresIn: String
    var localId: String
}

private struct RefreshResponse: Decodable {
    var id_token: String
    var refresh_token: String
    var expires_in: String
    var user_id: String
}

private struct FirebaseErrorEnvelope: Decodable {
    struct Detail: Decodable {
        var message: String
    }
    var error: Detail
}

private struct OAuthError: Decodable {
    var error: String?
    var error_description: String?
}

private struct FSBody: Encodable {
    var fields: [String: FSValue]
}

private enum FSValue: Encodable {
    case string(String)
    case double(Double)
    case bool(Bool)
    case timestamp(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .string(let value):
            try container.encode(value, forKey: .stringValue)
        case .double(let value):
            try container.encode(value, forKey: .doubleValue)
        case .bool(let value):
            try container.encode(value, forKey: .booleanValue)
        case .timestamp(let value):
            try container.encode(value, forKey: .timestampValue)
        }
    }

    private enum Key: String, CodingKey {
        case stringValue
        case doubleValue
        case booleanValue
        case timestampValue
    }
}

private struct FSList: Decodable {
    var documents: [FSDocument]?
    var nextPageToken: String?
}

private struct FSDocument: Decodable {
    var name: String
    var fields: [String: FSField]?
}

private struct FSField: Decodable {
    var stringValue: String?
    var doubleValue: Double?
    var integerValue: String?
    var booleanValue: Bool?
    var timestampValue: String?

    var number: Double? {
        if let doubleValue { return doubleValue }
        if let integerValue { return Double(integerValue) }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case stringValue
        case doubleValue
        case integerValue
        case booleanValue
        case timestampValue
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stringValue = try container.decodeIfPresent(String.self, forKey: .stringValue)
        booleanValue = try container.decodeIfPresent(Bool.self, forKey: .booleanValue)
        timestampValue = try container.decodeIfPresent(String.self, forKey: .timestampValue)
        integerValue = try container.decodeIfPresent(String.self, forKey: .integerValue)
        if let number = try? container.decode(Double.self, forKey: .doubleValue) {
            doubleValue = number
        } else if let text = try? container.decode(String.self, forKey: .doubleValue) {
            doubleValue = Double(text)
        } else {
            doubleValue = nil
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        encodeClosure = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
