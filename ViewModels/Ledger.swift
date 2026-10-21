import Foundation

struct MovementItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let amount: Double
    let category: ExpenseCategory
    let date: Date
    let note: String?
    let isSynced: Bool
}

struct MovementDayGroup: Identifiable, Equatable, Sendable {
    let day: Date
    let items: [MovementItem]

    var id: Date { day }
    var total: Double { items.reduce(0) { $0 + $1.amount } }
}

enum HistoryScope: String, CaseIterable, Identifiable, Sendable {
    case month = "Mes"
    case year = "Año"

    var id: String { rawValue }
}

/// Periodo del histórico: un mes concreto o un año completo.
struct HistoryPeriod: Equatable, Sendable {
    let scope: HistoryScope
    /// Primer día del mes o del año.
    let start: Date

    init(scope: HistoryScope, containing date: Date = .now, calendar: Calendar = .current) {
        self.scope = scope
        let components: Set<Calendar.Component> = scope == .month ? [.year, .month] : [.year]
        self.start = calendar.date(from: calendar.dateComponents(components, from: date)) ?? date
    }

    private var unit: Calendar.Component { scope == .month ? .month : .year }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(date, equalTo: start, toGranularity: unit)
    }

    /// Mueve el periodo `value` meses o años (negativo = hacia atrás).
    func shifted(by value: Int, calendar: Calendar = .current) -> HistoryPeriod {
        let moved = calendar.date(byAdding: unit, value: value, to: start) ?? start
        return HistoryPeriod(scope: scope, containing: moved, calendar: calendar)
    }

    /// Cambia entre mes y año conservando el contexto: de mes a año usa ese año;
    /// de año a mes usa el mes actual si es el año en curso y diciembre si es un año pasado.
    func switching(to newScope: HistoryScope, now: Date = .now, calendar: Calendar = .current) -> HistoryPeriod {
        guard newScope != scope else { return self }
        switch newScope {
        case .year:
            return HistoryPeriod(scope: .year, containing: start, calendar: calendar)
        case .month:
            if calendar.isDate(start, equalTo: now, toGranularity: .year) {
                return HistoryPeriod(scope: .month, containing: now, calendar: calendar)
            }
            let december = calendar.date(byAdding: .month, value: 11, to: start) ?? start
            return HistoryPeriod(scope: .month, containing: december, calendar: calendar)
        }
    }

    /// Días (en un mes) o meses (en un año) transcurridos del periodo; sirve para calcular promedios.
    func elapsedUnits(now: Date = .now, calendar: Calendar = .current) -> Int {
        let isCurrent = contains(now, calendar: calendar)
        switch scope {
        case .month:
            if isCurrent { return max(1, calendar.component(.day, from: now)) }
            return calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        case .year:
            if isCurrent { return max(1, calendar.component(.month, from: now)) }
            return 12
        }
    }

    func title() -> String {
        switch scope {
        case .month: MoneyFormat.capitalizedFirst(MoneyFormat.monthTitle(start))
        case .year: start.formatted(.dateTime.year().locale(MoneyFormat.locale))
        }
    }
}

/// Total de un mes dentro de la vista anual.
struct MonthTotal: Identifiable, Equatable, Sendable {
    let month: Date
    let total: Double
    let count: Int

    var id: Date { month }
}

struct CategorySlice: Identifiable, Equatable, Sendable {
    let category: ExpenseCategory
    let total: Double
    let percent: Double

    var id: String { category.id }
}

extension Sequence where Element == CategorySlice {
    var total: Double { reduce(0) { $0 + $1.total } }
}

/// Fuente de verdad de los números de la app. Se calcula una vez por cambio de datos
/// y todas las pantallas leen de aquí en lugar de repetir filtros y sumas.
struct Ledger: Equatable, Sendable {
    /// Cambia solo cuando hay que reevaluar el aviso de límite.
    struct AlertKey: Equatable, Sendable {
        let spent: Double
        let budget: Double
    }

    static let empty = Ledger(items: [], budget: 0)

    /// Del más reciente al más antiguo.
    let items: [MovementItem]
    let budget: Double
    let monthSpent: Double
    let todaySpent: Double

    init(items: [MovementItem], budget: Double, now: Date = .now, calendar: Calendar = .current) {
        let sorted = items.sorted { $0.date > $1.date }
        var month = 0.0
        var today = 0.0
        for item in sorted {
            if calendar.isDate(item.date, equalTo: now, toGranularity: .month) {
                month += item.amount
            }
            if calendar.isDate(item.date, inSameDayAs: now) {
                today += item.amount
            }
        }
        self.items = sorted
        self.budget = budget
        self.monthSpent = month
        self.todaySpent = today
    }

    var remaining: Double { budget - monthSpent }
    var ratio: Double { budget > 0 ? monthSpent / budget : 0 }
    var isAtLimit: Bool { budget > 0 && ratio >= 0.9 }
    var isOverBudget: Bool { budget > 0 && ratio >= 1 }
    var alertKey: AlertKey { AlertKey(spent: monthSpent, budget: budget) }

    func recent(_ limit: Int) -> [MovementItem] {
        Array(items.prefix(limit))
    }

    /// Movimientos agrupados por día, opcionalmente de una sola categoría.
    func groups(category: ExpenseCategory? = nil, calendar: Calendar = .current) -> [MovementDayGroup] {
        let source = category.map { selected in items.filter { $0.category == selected } } ?? items
        return Dictionary(grouping: source) { calendar.startOfDay(for: $0.date) }
            .map { MovementDayGroup(day: $0.key, items: $0.value) }
            .sorted { $0.day > $1.day }
    }

    // MARK: Histórico

    func items(in period: HistoryPeriod, calendar: Calendar = .current) -> [MovementItem] {
        items.filter { period.contains($0.date, calendar: calendar) }
    }

    func total(in period: HistoryPeriod, calendar: Calendar = .current) -> Double {
        items(in: period, calendar: calendar).reduce(0) { $0 + $1.amount }
    }

    /// Se puede retroceder mientras exista algún movimiento en un periodo anterior.
    func canGoBack(from period: HistoryPeriod, calendar: Calendar = .current) -> Bool {
        guard let oldest = items.last?.date else { return false }
        return HistoryPeriod(scope: period.scope, containing: oldest, calendar: calendar).start < period.start
    }

    /// No se avanza más allá del mes o año actual.
    func canGoForward(from period: HistoryPeriod, now: Date = .now, calendar: Calendar = .current) -> Bool {
        period.start < HistoryPeriod(scope: period.scope, containing: now, calendar: calendar).start
    }

    /// Los 12 meses del año de `period`, de enero a diciembre, con su total y número de gastos.
    func monthlyTotals(in period: HistoryPeriod, calendar: Calendar = .current) -> [MonthTotal] {
        let year = HistoryPeriod(scope: .year, containing: period.start, calendar: calendar)
        let inYear = items(in: year, calendar: calendar)
        return (0..<12).compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: offset, to: year.start) else { return nil }
            let monthItems = inYear.filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            return MonthTotal(month: month, total: monthItems.reduce(0) { $0 + $1.amount }, count: monthItems.count)
        }
    }

    /// Gasto por categoría, de mayor a menor, con su porcentaje del total del periodo.
    func slices(in period: HistoryPeriod, calendar: Calendar = .current) -> [CategorySlice] {
        let scoped = items(in: period, calendar: calendar)
        let totals = Dictionary(grouping: scoped, by: \.category)
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        let sum = totals.values.reduce(0, +)
        return totals
            .sorted { $0.value > $1.value }
            .map { CategorySlice(category: $0.key, total: $0.value, percent: sum > 0 ? $0.value / sum : 0) }
    }
}
