import Foundation

/// Formato y lectura de dinero en pesos mexicanos (es_MX).
enum MoneyFormat {
    static let locale = Locale(identifier: "es_MX")
    static let maxAmount: Double = 1_000_000

    // MARK: Formato de salida

    static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "MXN").locale(locale))
    }

    static func currencyShort(_ value: Double) -> String {
        value.formatted(.currency(code: "MXN").precision(.fractionLength(0)).locale(locale))
    }

    static func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0)).locale(locale))
    }

    static func monthTitle(_ date: Date = .now) -> String {
        date.formatted(.dateTime.month(.wide).year().locale(locale))
    }

    static func movementDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).hour().minute().locale(locale))
    }

    /// Primera letra en mayúscula sin tocar el resto ("octubre de 2026" -> "Octubre de 2026").
    static func capitalizedFirst(_ text: String) -> String {
        text.prefix(1).uppercased() + text.dropFirst()
    }

    static func dayTitle(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Hoy" }
        if calendar.isDateInYesterday(date) { return "Ayer" }
        return capitalizedFirst(date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale)))
    }

    /// Texto para un campo editable, con comas en los millares (`8,000` o `1,234.5`).
    static func editable(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// Da formato a lo que se va escribiendo: comas en los millares, punto decimal y máximo dos decimales.
    /// Una coma al final se toma como decimal (teclados que la usan) porque las demás las pone esta función.
    static func liveFormat(_ raw: String) -> String {
        var text = raw
        if text.hasSuffix(",") {
            text.removeLast()
            if !text.contains(".") { text.append(".") }
        }
        var integer = ""
        var fraction = ""
        var hasDecimal = false
        for character in text {
            if let digit = character.wholeNumberValue, character.isASCII {
                if hasDecimal {
                    if fraction.count < 2 { fraction.append(String(digit)) }
                } else if integer.count < 7 {
                    integer.append(String(digit))
                }
            } else if character == "." {
                hasDecimal = true
            }
        }
        while integer.count > 1, integer.hasPrefix("0") { integer.removeFirst() }
        if integer.isEmpty { integer = hasDecimal ? "0" : "" }

        var grouped = ""
        for (offset, character) in integer.reversed().enumerated() {
            if offset > 0, offset % 3 == 0 { grouped.append(",") }
            grouped.append(character)
        }
        grouped = String(grouped.reversed())
        return hasDecimal ? "\(grouped).\(fraction)" : grouped
    }

    // MARK: Lectura de entrada

    /// Lee lo que escribe el usuario. Acepta `85`, `85.5`, `85,5`, `8,000`, `1,234.50` y `1.234,50`.
    /// Devuelve `nil` si no es un monto válido (cero, negativo o mayor a `maxAmount`).
    static func parse(_ raw: String) -> Double? {
        let cleaned = raw.filter { $0.isNumber || $0 == "." || $0 == "," }
        guard !cleaned.isEmpty,
              let value = Double(normalize(cleaned)),
              value > 0, value <= maxAmount else {
            return nil
        }
        return (value * 100).rounded() / 100
    }

    private static func normalize(_ text: String) -> String {
        switch (text.lastIndex(of: ","), text.lastIndex(of: ".")) {
        case let (comma?, dot?):
            // Con ambos símbolos, el último es el decimal y el otro agrupa miles.
            let decimal: Character = comma > dot ? "," : "."
            let grouping: Character = decimal == "," ? "." : ","
            return String(text.filter { $0 != grouping }).replacingOccurrences(of: String(decimal), with: ".")
        case (.some, nil):
            return normalize(text, separator: ",")
        case (nil, .some):
            return normalize(text, separator: ".")
        case (nil, nil):
            return text
        }
    }

    private static func normalize(_ text: String, separator: Character) -> String {
        let parts = text.split(separator: separator, omittingEmptySubsequences: false)
        let isGrouping = parts.count > 2
            || (separator == "," && parts.count == 2 && parts[0].count >= 1 && parts[1].count == 3)
        if isGrouping {
            return text.replacingOccurrences(of: String(separator), with: "")
        }
        return text.replacingOccurrences(of: String(separator), with: ".")
    }
}
