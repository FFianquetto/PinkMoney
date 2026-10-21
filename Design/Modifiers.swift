import SwiftUI

// MARK: - Superficies

enum PinkCardStyle {
    case surface
    case muted
    case forest
    case rose

    var fill: Color {
        switch self {
        case .surface: PinkPalette.surface
        case .muted: PinkPalette.surfaceMuted
        case .forest: PinkPalette.forest
        case .rose: PinkPalette.roseSoft
        }
    }

    var border: Color {
        switch self {
        case .surface, .muted: PinkPalette.hairline
        case .forest: PinkPalette.rose.opacity(0.22)
        case .rose: PinkPalette.rose.opacity(0.35)
        }
    }

    var shadow: Color {
        switch self {
        case .surface: Color.black.opacity(0.35)
        case .forest: Color.black.opacity(0.45)
        case .muted, .rose: .clear
        }
    }
}

private struct PinkSurface: ViewModifier {
    let style: PinkCardStyle
    let radius: CGFloat
    let elevated: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(style.fill, in: shape)
            .overlay(shape.strokeBorder(style.border, lineWidth: 1))
            .shadow(color: elevated ? style.shadow : .clear, radius: 14, y: 6)
    }
}

extension View {
    /// Fondo, borde y sombra de la paleta. Es la única fuente del aspecto de tarjetas y filas.
    func pinkSurface(
        _ style: PinkCardStyle = .surface,
        radius: CGFloat = PinkTheme.Radius.row,
        elevated: Bool = false
    ) -> some View {
        modifier(PinkSurface(style: style, radius: radius, elevated: elevated))
    }
}

// MARK: - Campos de dinero

extension View {
    /// Mantiene el texto del campo con comas en los millares mientras se escribe.
    func groupedMoney(_ text: Binding<String>) -> some View {
        onChange(of: text.wrappedValue) { _, newValue in
            let formatted = MoneyFormat.liveFormat(newValue)
            if formatted != newValue { text.wrappedValue = formatted }
        }
    }
}

// MARK: - Tipografía

extension Text {
    /// Etiqueta pequeña en mayúsculas (por ejemplo "FLUJO 01" del storyboard).
    func pinkEyebrow(_ color: Color = PinkPalette.accent, tracking: CGFloat = 1.2) -> Text {
        self.font(PinkTheme.Font.eyebrow())
            .tracking(tracking)
            .foregroundStyle(color)
    }
}
