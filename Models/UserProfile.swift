import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: String
    var email: String
    var monthlyBudget: Double
    var sessionToken: String?
    // Valores por defecto: permiten migrar bases anteriores sin perder datos.
    var displayName: String = ""
    var school: String = ""

    init(
        id: String,
        email: String,
        monthlyBudget: Double,
        sessionToken: String? = nil,
        displayName: String = "",
        school: String = ""
    ) {
        self.id = id
        self.email = email
        self.monthlyBudget = monthlyBudget
        self.sessionToken = sessionToken
        self.displayName = displayName
        self.school = school
    }
}

extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case monthlyBudget
        case sessionToken
        case displayName
        case school
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let email = try container.decode(String.self, forKey: .email)
        let monthlyBudget = try container.decode(Double.self, forKey: .monthlyBudget)
        let sessionToken = try container.decodeIfPresent(String.self, forKey: .sessionToken)
        let displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        let school = try container.decodeIfPresent(String.self, forKey: .school) ?? ""
        self.init(
            id: id,
            email: email,
            monthlyBudget: monthlyBudget,
            sessionToken: sessionToken,
            displayName: displayName,
            school: school
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(monthlyBudget, forKey: .monthlyBudget)
        try container.encodeIfPresent(sessionToken, forKey: .sessionToken)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(school, forKey: .school)
    }
}

struct ProfileSnapshot: Equatable, Sendable {
    var id: String
    var email: String
    var monthlyBudget: Double
    var sessionToken: String?
    var usesCloud: Bool
    var displayName = ""
    var school = ""
}
