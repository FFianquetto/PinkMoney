import SwiftUI

/// Círculo con el ícono SF Symbol y el color de la categoría.
struct CategoryBadge: View {
    let category: ExpenseCategory
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(category.color)
            .frame(width: size, height: size)
            .background(category.color.opacity(0.16), in: Circle())
            .accessibilityHidden(true)
    }
}

/// Celda seleccionable del selector de categorías.
struct CategoryPill: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.symbolName)
                    .font(.title3.weight(.semibold))
                Text(category.title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? Color.white : category.color)
            .frame(maxWidth: .infinity, minHeight: 82)
            .background(
                RoundedRectangle(cornerRadius: PinkTheme.Radius.control, style: .continuous)
                    .fill(isSelected ? category.color : category.color.opacity(0.13))
            )
            .overlay(
                RoundedRectangle(cornerRadius: PinkTheme.Radius.control, style: .continuous)
                    .strokeBorder(category.color.opacity(isSelected ? 0 : 0.25), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.03 : 1)
            .animation(.spring(duration: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Chip horizontal de filtro (historial por categoría).
struct PinkFilterChip: View {
    let title: String
    let symbol: String
    let tint: Color
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                Text(title)
                    .font(.footnote.weight(.bold))
            }
            .foregroundStyle(isOn ? Color.white : tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Capsule().fill(isOn ? tint : tint.opacity(0.13)))
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Fila de chips: "Todo" más una por categoría. Tocar la activa vuelve a "Todo".
struct CategoryFilterBar: View {
    @Binding var selection: ExpenseCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PinkFilterChip(title: "Todo", symbol: "square.grid.2x2.fill", tint: PinkPalette.forestSoft, isOn: selection == nil) {
                    selection = nil
                }
                ForEach(ExpenseCategory.allCases) { category in
                    PinkFilterChip(
                        title: category.title,
                        symbol: category.symbolName,
                        tint: category.color,
                        isOn: selection == category
                    ) {
                        selection = (selection == category) ? nil : category
                    }
                }
            }
        }
    }
}
