import Foundation

enum FirebaseConfig {
    /// Pega aquí la API_KEY de GoogleService-Info.plist.
    static var apiKeyOverride = ""
    /// Pega aquí el PROJECT_ID de GoogleService-Info.plist.
    static var projectIDOverride = ""

    static var apiKey: String {
        if let override = normalized(apiKeyOverride) { return override }
        return plistValue("API_KEY") ?? ""
    }

    static var projectID: String {
        if let override = normalized(projectIDOverride) { return override }
        return plistValue("PROJECT_ID") ?? ""
    }

    static var isConfigured: Bool {
        !apiKey.isEmpty && !projectID.isEmpty
    }

    private static func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func plistValue(_ key: String) -> String? {
        if let bundled = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           let value = normalized(bundled) {
            return value
        }
        guard let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dictionary = object as? [String: Any],
              let raw = dictionary[key] as? String else {
            return nil
        }
        return normalized(raw)
    }
}
