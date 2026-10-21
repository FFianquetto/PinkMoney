import Foundation
import SwiftData

@MainActor
protocol UserRepository: AnyObject {
    func find(id: String) throws -> UserProfile?
    func current() throws -> UserProfile?
    func upsert(id: String, email: String, budget: Double?, sessionToken: String?) throws -> UserProfile
    func updateBudget(userID: String, amount: Double) throws
    func updateSessionToken(userID: String, token: String?) throws
    func updateDetails(userID: String, displayName: String, school: String, email: String?) throws
    func deleteAll() throws
}

@MainActor
final class SwiftDataUserRepository: UserRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func find(id: String) throws -> UserProfile? {
        var descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try context.fetchPink(descriptor).first
    }

    func current() throws -> UserProfile? {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        return try context.fetchPink(descriptor).first
    }

    func upsert(id: String, email: String, budget: Double?, sessionToken: String?) throws -> UserProfile {
        if let existing = try find(id: id) {
            existing.email = email
            if let budget {
                existing.monthlyBudget = budget
            }
            existing.sessionToken = sessionToken
            try context.persistPink()
            return existing
        }

        let profile = UserProfile(
            id: id,
            email: email,
            monthlyBudget: budget ?? PinkTheme.defaultBudget,
            sessionToken: sessionToken
        )
        context.insert(profile)
        try context.persistPink()
        return profile
    }

    func updateBudget(userID: String, amount: Double) throws {
        guard let profile = try find(id: userID) else {
            throw PinkMoneyError.localStore("No hay perfil para actualizar el presupuesto.")
        }
        profile.monthlyBudget = amount
        try context.persistPink()
    }

    func updateSessionToken(userID: String, token: String?) throws {
        guard let profile = try find(id: userID) else { return }
        profile.sessionToken = token
        try context.persistPink()
    }

    func updateDetails(userID: String, displayName: String, school: String, email: String?) throws {
        guard let profile = try find(id: userID) else {
            throw PinkMoneyError.localStore("No hay perfil para actualizar.")
        }
        profile.displayName = displayName
        profile.school = school
        if let email { profile.email = email }
        try context.persistPink()
    }

    func deleteAll() throws {
        try context.erasePink(UserProfile.self)
    }
}
