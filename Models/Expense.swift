import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var category: String
    var date: Date
    var note: String?
    var isSynced: Bool

    init(
        id: UUID = UUID(),
        amount: Double,
        category: String,
        date: Date = .now,
        note: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
        self.isSynced = isSynced
    }

    var expenseCategory: ExpenseCategory {
        get { ExpenseCategory(rawValue: category) ?? .despensa }
        set { category = newValue.rawValue }
    }

    func payload() -> ExpensePayload {
        ExpensePayload(
            id: id,
            amount: amount,
            category: category,
            date: date,
            note: note,
            isSynced: isSynced
        )
    }
}

extension Expense: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case category
        case date
        case note
        case isSynced
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let amount = try container.decode(Double.self, forKey: .amount)
        let category = try container.decode(String.self, forKey: .category)
        let date = try container.decode(Date.self, forKey: .date)
        let note = try container.decodeIfPresent(String.self, forKey: .note)
        let isSynced = try container.decodeIfPresent(Bool.self, forKey: .isSynced) ?? false
        self.init(
            id: id,
            amount: amount,
            category: category,
            date: date,
            note: note,
            isSynced: isSynced
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(amount, forKey: .amount)
        try container.encode(category, forKey: .category)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(note, forKey: .note)
        try container.encode(isSynced, forKey: .isSynced)
    }
}

struct ExpensePayload: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var amount: Double
    var category: String
    var date: Date
    var note: String?
    var isSynced: Bool
}
