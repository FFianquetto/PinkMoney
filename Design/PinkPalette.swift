import SwiftUI
import UIKit

/// La app usa siempre el tema oscuro: negro con rosa oscuro y rosa brillante como acento.
/// Paleta tomada del Storyboard Técnico de Pink Money:
/// verde bosque `#1A201B`, salvia `#596A5C` / `#9AB2A0`, crema `#FAF8F5`,
/// rosa polvo `#D8A7A0` y rojo de alerta `#FF3B30`. El vino viene de los nodos del diagrama de flujo.
enum PinkPalette {
    // MARK: Superficies
    static let canvas = Color(light: 0xFAF8F5, dark: 0x0B0608)
    static let surface = Color(light: 0xFFFFFF, dark: 0x1B1116)
    static let surfaceMuted = Color(light: 0xF2EFEA, dark: 0x2A1920)
    static let hairline = Color(light: 0xE7E2DA, dark: 0x3F2630)

    // MARK: Texto
    static let ink = Color(light: 0x1A201B, dark: 0xFFF8F9)
    static let inkSoft = Color(light: 0x596A5C, dark: 0xEFD5DC)
    static let inkFaint = Color(light: 0x8E8E93, dark: 0xC4A8B0)

    // MARK: Marca
    // En oscuro `forest` es el vino de las tarjetas destacadas (el nombre viene del storyboard original).
    static let forest = Color(light: 0x1A201B, dark: 0x5A1D33)
    static let forestSoft = Color(light: 0x313C33, dark: 0x7B2A47)
    static let onForest = Color(light: 0xFAF8F5, dark: 0xFAF8F5)
    static let sage = Color(light: 0x9AB2A0, dark: 0x9AB2A0)
    static let sageDeep = Color(light: 0x596A5C, dark: 0xA6BEA7)
    static let rose = Color(light: 0xD8A7A0, dark: 0xD8A7A0)
    static let roseSoft = Color(light: 0xF4E5E2, dark: 0x3A1D27)
    static let roseDeep = Color(light: 0xB87C75, dark: 0xE3B5AF)
    static let wine = Color(light: 0x5C1A2E, dark: 0xE6B9C2)

    // MARK: Acento y estados
    static let accent = Color(light: 0x9C4A5A, dark: 0xF2A7BA)
    static let buttonFill = Color(light: 0x1A201B, dark: 0xF2A7BA)
    static let onButton = Color(light: 0xFAF8F5, dark: 0x1E0A12)
    static let danger = Color(light: 0xFF3B30, dark: 0xFF6A60)
    static let warning = Color(light: 0xC9964A, dark: 0xE0B068)
    static let success = Color(light: 0x4F8A63, dark: 0x7DBE92)
}

extension Color {
    /// Color dinámico para modo claro y oscuro a partir de valores hexadecimales.
    init(light: UInt32, dark: UInt32) {
        self = Color(
            uiColor: UIColor { traits in
                UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
            }
        )
    }

    init(hex: UInt32, opacity: Double = 1) {
        self = Color(uiColor: UIColor(hex: hex, alpha: opacity))
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}
