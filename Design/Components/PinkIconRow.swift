import SwiftUI

/// Fila con ícono en círculo, título y mensaje. Con acción se comporta como botón con flecha.
struct PinkIconRow: View {
    let systemImage: String
    let title: String
    let message: String
    var tint: Color = PinkPalette.accent
    var iconBackground: Color = PinkPalette.roseSoft
    var action: (() -> Void)?

    var body: some View {
        if let action {
            Button(action: action) { row(showsArrow: true) }
                .buttonStyle(.plain)
        } else {
            row(showsArrow: false)
        }
    }

    private func row(showsArrow: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 46, height: 46)
                .background(iconBackground, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PinkPalette.ink)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(PinkPalette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if showsArrow {
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PinkPalette.inkSoft)
            }
        }
        .padding(16)
        .contentShape(Rectangle())
        .pinkSurface(radius: PinkTheme.Radius.card)
    }
}
