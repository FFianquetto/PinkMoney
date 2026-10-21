import Foundation
import SwiftData

enum LocalDatabase {
    static func makeContainer() -> ModelContainer {
        let schema = Schema([Expense.self, UserProfile.self])
        let configuration = ModelConfiguration(
            "PinkMoney",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        if let container = try? ModelContainer(for: schema, configurations: configuration) {
            return container
        }

        // Si la base no abre, se aparta como respaldo en lugar de borrarla.
        let fileManager = FileManager.default
        let url = configuration.url
        let stamp = Int(Date().timeIntervalSince1970)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: url.path + suffix)
            let backup = URL(fileURLWithPath: url.path + suffix + ".respaldo-\(stamp)")
            try? fileManager.moveItem(at: source, to: backup)
        }

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Pink Money no pudo abrir la base local: \(error.localizedDescription)")
        }
    }
}

extension ModelContext {
    func persistPink() throws {
        do {
            try save()
        } catch {
            throw PinkMoneyError.localStore(error.localizedDescription)
        }
    }

    func fetchPink<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        do {
            return try fetch(descriptor)
        } catch {
            throw PinkMoneyError.localStore(error.localizedDescription)
        }
    }

    func erasePink<T: PersistentModel>(_ type: T.Type) throws {
        do {
            try delete(model: type)
            try save()
        } catch {
            throw PinkMoneyError.localStore(error.localizedDescription)
        }
    }
}
