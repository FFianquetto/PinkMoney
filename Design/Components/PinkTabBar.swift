import SwiftUI
import UIKit

// MARK: - Espacio reservado para la barra

private struct BarClearanceKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    /// Alto que ocupa la barra inferior flotante. Los scrolls lo suman al final para que nada quede tapado.
    var barClearance: CGFloat {
        get { self[BarClearanceKey.self] }
        set { self[BarClearanceKey.self] = newValue }
    }
}

/// Barra inferior flotante con íconos. Dos pestañas a cada lado y un botón central "+" para registrar un gasto.
struct PinkTabBar<Tag: Hashable>: View {
    struct Item: Identifiable {
        let tag: Tag
        let title: String
        let symbol: String
        var id: Tag { tag }
    }

    let leading: [Item]
    let trailing: [Item]
    @Binding var selection: Tag
    let onAdd: () -> Void

    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 0) {
            ForEach(leading) { tabButton($0) }
            addButton
            ForEach(trailing) { tabButton($0) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(PinkPalette.surface.opacity(0.96), in: Capsule())
        .overlay(Capsule().strokeBorder(PinkPalette.rose.opacity(0.28), lineWidth: 1))
        .shadow(color: .black.opacity(0.55), radius: 18, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    private func tabButton(_ item: Item) -> some View {
        let isSelected = selection == item.tag
        return Button {
            guard !isSelected else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(duration: 0.35, bounce: 0.25)) {
                selection = item.tag
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: 19, weight: isSelected ? .bold : .medium))
                    .symbolVariant(isSelected ? .fill : .none)
                Text(item.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? PinkPalette.accent : PinkPalette.inkFaint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    Capsule()
                        .fill(PinkPalette.accent.opacity(0.16))
                        .matchedGeometryEffect(id: "highlight", in: highlight)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var addButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onAdd()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(PinkPalette.onButton)
                .frame(width: 48, height: 48)
                .background(PinkPalette.buttonFill, in: Circle())
                .shadow(color: PinkPalette.accent.opacity(0.45), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .accessibilityLabel("Registrar gasto")
    }
}
