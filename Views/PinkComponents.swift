import SwiftUI

// MARK: - Fondo

/// Fondo negro con dos resplandores: rosa brillante arriba y vino abajo, para dar contraste y profundidad.
struct PinkScreen<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            PinkPalette.canvas
                .ignoresSafeArea()
            GeometryReader { proxy in
                glow(Color(hex: 0xF2A7BA).opacity(0.30), size: 420)
                    .position(x: proxy.size.width * 0.95, y: -20)
                glow(Color(hex: 0x8E2A55).opacity(0.55), size: 460)
                    .position(x: -20, y: proxy.size.height * 0.88)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            content
        }
    }

    /// Resplandor con degradado radial: se ve igual que un desenfoque pero no pesa al hacer scroll.
    private func glow(_ color: Color, size: CGFloat) -> some View {
        Circle()
            .fill(RadialGradient(colors: [color, .clear], center: .center, startRadius: 0, endRadius: size / 2))
            .frame(width: size, height: size)
    }
}

// MARK: - Scroll

/// Scroll vertical estándar de las pantallas: márgenes, espacio para la barra inferior y teclado que se cierra al arrastrar.
struct PinkScrollView<Content: View>: View {
    @Environment(\.barClearance) private var barClearance
    /// Cada vez que cambia este valor el scroll vuelve al inicio.
    var scrollToTopToken = 0
    @ViewBuilder var content: Content

    private let topID = "pink.scroll.top"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: PinkTheme.Spacing.section) {
                    content
                }
                .padding(.horizontal, PinkTheme.Spacing.screen)
                .padding(.top, 8)
                .padding(.bottom, 24 + barClearance)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(topID)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.always, axes: .vertical)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: scrollToTopToken) { _, _ in
                withAnimation(.snappy) { proxy.scrollTo(topID, anchor: .top) }
            }
        }
    }
}

// MARK: - Tarjeta

struct PinkCard<Content: View>: View {
    var style: PinkCardStyle = .surface
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    init(style: PinkCardStyle = .surface, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.style = style
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pinkSurface(style, radius: PinkTheme.Radius.card, elevated: true)
    }
}

// MARK: - Botones

struct PinkPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(PinkPalette.onButton)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                PinkPalette.buttonFill,
                in: RoundedRectangle(cornerRadius: PinkTheme.Radius.control, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.40), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

struct PinkSoftButtonStyle: ButtonStyle {
    var tint: Color = PinkPalette.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                tint.opacity(0.14),
                in: RoundedRectangle(cornerRadius: PinkTheme.Radius.control, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(duration: 0.25), value: configuration.isPressed)
    }
}

/// Contenido común de botones: spinner, ícono opcional y título.
private struct ButtonLabel: View {
    let title: String
    let systemImage: String?
    let isLoading: Bool
    var spinnerTint: Color?

    var body: some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView().tint(spinnerTint)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.body.weight(.bold))
            }
            Text(title)
        }
    }
}

/// Botón primario oscuro y grande, como `+ Registrar Gasto` del storyboard.
struct PrimaryDarkButton: View {
    let title: String
    var systemImage: String?
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ButtonLabel(title: title, systemImage: systemImage, isLoading: isLoading, spinnerTint: PinkPalette.onButton)
        }
        .buttonStyle(PinkPrimaryButtonStyle())
        .disabled(isLoading)
    }
}

struct PinkSoftButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = PinkPalette.accent
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ButtonLabel(title: title, systemImage: systemImage, isLoading: isLoading, spinnerTint: nil)
        }
        .buttonStyle(PinkSoftButtonStyle(tint: tint))
        .disabled(isLoading)
    }
}

/// Píldora compacta para atajos (montos rápidos, ajustes de presupuesto).
struct PinkPillButton: View {
    enum Tone {
        case onForest
        case neutral
    }

    let title: String
    var tone: Tone = .neutral
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(tone == .onForest ? PinkPalette.onForest : PinkPalette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(tone == .onForest ? PinkPalette.onForest.opacity(0.12) : PinkPalette.surfaceMuted, in: Capsule())
                .overlay(Capsule().strokeBorder(tone == .onForest ? Color.clear : PinkPalette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
