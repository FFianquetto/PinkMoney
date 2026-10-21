import SwiftUI

/// "El Cerdo con lentes": mascota dibujada con formas de SwiftUI en la paleta rosa polvo.
struct CerdoMascot: View {
    var size: CGFloat = 168

    private var skin: Color { Color(hex: 0xF2CFC9) }
    private var skinDeep: Color { Color(hex: 0xD8A7A0) }
    private var nostril: Color { Color(hex: 0x8C5550) }
    private var frame: Color { Color(hex: 0x1A201B) }

    var body: some View {
        ZStack {
            ear(offsetX: -size * 0.24, rotation: -16)
            ear(offsetX: size * 0.24, rotation: 16)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [skin, Color(hex: 0xEBBDB6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.74, height: size * 0.74)
                .shadow(color: Color.black.opacity(0.18), radius: size * 0.05, y: size * 0.04)

            HStack(spacing: size * 0.20) {
                blush
                blush
            }
            .offset(y: size * 0.09)

            HStack(spacing: size * 0.22) {
                eye
                eye
            }
            .offset(y: -size * 0.07)

            glasses
                .offset(y: -size * 0.07)

            snout
                .offset(y: size * 0.16)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cerdo con lentes")
    }

    private func ear(offsetX: CGFloat, rotation: Double) -> some View {
        ZStack {
            Ellipse()
                .fill(skin)
                .frame(width: size * 0.22, height: size * 0.28)
            Ellipse()
                .fill(skinDeep)
                .frame(width: size * 0.11, height: size * 0.15)
                .offset(y: size * 0.02)
        }
        .rotationEffect(.degrees(rotation))
        .offset(x: offsetX, y: -size * 0.30)
    }

    private var blush: some View {
        Ellipse()
            .fill(Color(hex: 0xD98C86).opacity(0.45))
            .frame(width: size * 0.11, height: size * 0.055)
    }

    private var eye: some View {
        Circle()
            .fill(frame)
            .frame(width: size * 0.045, height: size * 0.045)
    }

    private var glasses: some View {
        HStack(spacing: 0) {
            lens
            Rectangle()
                .fill(frame)
                .frame(width: size * 0.07, height: max(2, size * 0.016))
            lens
        }
    }

    private var lens: some View {
        RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
            .stroke(frame, lineWidth: max(2, size * 0.016))
            .background(
                RoundedRectangle(cornerRadius: size * 0.06, style: .continuous)
                    .fill(Color.white.opacity(0.30))
            )
            .frame(width: size * 0.25, height: size * 0.18)
    }

    private var snout: some View {
        ZStack {
            Ellipse()
                .fill(skinDeep)
                .frame(width: size * 0.30, height: size * 0.22)
            HStack(spacing: size * 0.055) {
                Capsule()
                    .fill(nostril)
                    .frame(width: size * 0.035, height: size * 0.05)
                Capsule()
                    .fill(nostril)
                    .frame(width: size * 0.035, height: size * 0.05)
            }
        }
    }
}
