import SwiftUI

/// Tokens de diseño compartidos: radios, espacios, tipografía y banderas del flujo.
enum PinkTheme {
    static let defaultBudget: Double = 8_000

    /// El backend (Firebase) está pendiente. Con `false` la app abre directo en el menú principal
    /// y el usuario navega libremente. Cámbialo a `true` para reactivar el login del diagrama.
    static let requiresLogin = false

    /// Mientras sea `false`, toda la app lee y escribe solo en la base local (SwiftData):
    /// no hay llamadas a Firebase ni cola de sincronización activa. Actívalo cuando el backend esté listo.
    static let cloudSyncEnabled = false

    enum Radius {
        static let card: CGFloat = 26
        static let control: CGFloat = 18
        static let row: CGFloat = 20
        static let chip: CGFloat = 14
    }

    enum Spacing {
        static let screen: CGFloat = 20
        static let section: CGFloat = 22
        static let item: CGFloat = 12
    }

    enum Font {
        static func amountHero() -> SwiftUI.Font {
            .system(size: 44, weight: .bold, design: .rounded)
        }

        static func amount(_ style: SwiftUI.Font.TextStyle = .headline) -> SwiftUI.Font {
            .system(style, design: .rounded).weight(.bold)
        }

        static func eyebrow() -> SwiftUI.Font {
            .system(size: 11, weight: .bold, design: .rounded)
        }

        static func title(_ style: SwiftUI.Font.TextStyle = .title2) -> SwiftUI.Font {
            .system(style, design: .rounded).weight(.bold)
        }
    }
}
