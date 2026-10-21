import SwiftUI

/// Encabezado de sección con etiqueta pequeña tipo "FLUJO 01" y título.
struct PinkSectionHeader<Trailing: View>: View {
    let title: String
    var eyebrow: String?
    @ViewBuilder var trailing: Trailing

    init(_ title: String, eyebrow: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.eyebrow = eyebrow
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                if let eyebrow {
                    Text(eyebrow.uppercased()).pinkEyebrow()
                }
                Text(title)
                    .font(PinkTheme.Font.title(.title3))
                    .foregroundStyle(PinkPalette.ink)
            }
            Spacer(minLength: 8)
            trailing
        }
        .accessibilityAddTraits(.isHeader)
    }
}

extension PinkSectionHeader where Trailing == EmptyView {
    init(_ title: String, eyebrow: String? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.trailing = EmptyView()
    }
}

/// Encabezado grande de pantalla: etiqueta, título y subtítulo.
struct PinkScreenHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(eyebrow.uppercased()).pinkEyebrow(tracking: 1.6)
            Text(title)
                .font(PinkTheme.Font.title(.largeTitle))
                .foregroundStyle(PinkPalette.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(PinkPalette.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
