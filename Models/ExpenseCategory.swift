import SwiftUI

enum ExpenseCategory: String, CaseIterable, Codable, Identifiable {
    case renta
    case servicios
    case despensa
    case transporte
    case facultad
    case ocio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .renta: "Renta"
        case .servicios: "Servicios"
        case .despensa: "Despensa"
        case .transporte: "Transporte"
        case .facultad: "Facultad"
        case .ocio: "Ocio"
        }
    }

    var symbolName: String {
        switch self {
        case .renta: "house.fill"
        case .servicios: "bolt.fill"
        case .despensa: "cart.fill"
        case .transporte: "bus.fill"
        case .facultad: "graduationcap.fill"
        case .ocio: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .renta: Color(hex: 0x9C4A5A)
        case .servicios: Color(hex: 0xC9964A)
        case .despensa: Color(hex: 0x6F9477)
        case .transporte: Color(hex: 0x5B7C99)
        case .facultad: Color(hex: 0x8A7BA8)
        case .ocio: Color(hex: 0xD8A7A0)
        }
    }
}
