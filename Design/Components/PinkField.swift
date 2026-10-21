import SwiftUI

/// Contenedor de campo con etiqueta en mayúsculas, ícono opcional y fondo suave.
/// Toda el área es tocable: al tocar el borde se enfoca el campo de texto.
struct PinkField<Content: View>: View {
    let title: String
    var systemImage: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .pinkEyebrow(PinkPalette.inkSoft, tracking: 0.8)
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PinkPalette.sageDeep)
                        .frame(width: 20)
                }
                content
                    .foregroundStyle(PinkPalette.ink)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pinkSurface(.muted, radius: PinkTheme.Radius.control)
        }
    }
}
