import Foundation
import SwiftData

@MainActor
protocol ExpenseRepository: AnyObject {
    func fetchAll() throws -> [Expense]
    func fetchPending() throws -> [Expense]
    func insert(amount: Double, category: ExpenseCategory, note: String?) throws -> Expense
    func markSynced(id: UUID) throws
    func importCloud(_ payloads: [ExpensePayload]) throws
    func delete(id: UUID) throws
    func deleteAll() throws
}

@MainActor
final class SwiftDataExpenseRepository: ExpenseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        return try context.fetchPink(descriptor)
    }

    func fetchPending() throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.isSynced == false },
            sortBy: [SortDescriptor(\Expense.date, order: .forward)]
        )
        return try context.fetchPink(descriptor)
    }

    func insert(amount: Double, category: ExpenseCategory, note: String?) throws -> Expense {
        let expense = Expense(
            amount: amount,
            category: category.rawValue,
            note: note,
            isSynced: false
        )
        context.insert(expense)
        try context.persistPink()
        return expense
    }

    func markSynced(id: UUID) throws {
        var descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let expense = try context.fetchPink(descriptor).first else { return }
        expense.isSynced = true
        try context.persistPink()
    }

    func importCloud(_ payloads: [ExpensePayload]) throws {
        let known = Set(try fetchAll().map(\.id))
        var inserted = false
        for payload in payloads where !known.contains(payload.id) {
            let expense = Expense(
                id: payload.id,
                amount: payload.amount,
                category: payload.category,
                date: payload.date,
                note: payload.note,
                isSynced: true
            )
            context.insert(expense)
            inserted = true
        }
        if inserted {
            try context.persistPink()
        }
    }

    func delete(id: UUID) throws {
        var descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let expense = try context.fetchPink(descriptor).first else { return }
        context.delete(expense)
        try context.persistPink()
    }

    func deleteAll() throws {
        try context.erasePink(Expense.self)
    }
}
