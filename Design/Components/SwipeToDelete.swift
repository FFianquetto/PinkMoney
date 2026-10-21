import SwiftUI
import UIKit

/// Desliza la fila a la izquierda y se borra directo al soltar (si pasó el umbral).
/// Funciona dentro de un `ScrollView`, donde `.swipeActions` no existe. Si el borrado falla, la fila regresa.
struct SwipeToDelete<Content: View>: View {
    /// Devuelve `true` si el elemento se borró.
    let onDelete: () -> Bool
    @ViewBuilder var content: Content

    @State private var offset: CGFloat = 0
    @State private var width: CGFloat = 320
    @State private var isHorizontalDrag: Bool?
    @State private var isRemoving = false

    private var progress: CGFloat {
        min(1, -offset / SwipeDeleteRule.threshold(width: width))
    }

    var body: some View {
        // El contenedor no se mueve: el fondo rojo queda fijo y solo la fila se desplaza encima.
        ZStack {
            content
                .offset(x: offset)
                .simultaneousGesture(drag)
        }
        .background { trashBackground }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .accessibilityAction(named: "Borrar") { _ = onDelete() }
    }

    /// Fondo rojo que se revela detrás de la fila; el bote crece al llegar al umbral.
    private var trashBackground: some View {
        RoundedRectangle(cornerRadius: PinkTheme.Radius.row, style: .continuous)
            .fill(PinkPalette.danger)
            .overlay(alignment: .trailing) {
                Image(systemName: "trash.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .scaleEffect(progress >= 1 ? 1.25 : 0.9)
                    .padding(.trailing, 24)
                    .animation(.spring(duration: 0.2), value: progress >= 1)
            }
            .opacity(offset < -2 ? 1 : 0)
            .accessibilityHidden(true)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard !isRemoving else { return }
                // La primera dirección detectada decide si es scroll vertical o deslizar la fila.
                if isHorizontalDrag == nil {
                    isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isHorizontalDrag == true else { return }
                offset = min(0, value.translation.width)
            }
            .onEnded { value in
                defer { isHorizontalDrag = nil }
                guard isHorizontalDrag == true, !isRemoving else { return }
                let outcome = SwipeDeleteRule.outcome(
                    translation: value.translation.width,
                    predictedEnd: value.predictedEndTranslation.width,
                    width: width
                )
                switch outcome {
                case .delete: remove()
                case .cancel: withAnimation(.spring(duration: 0.3, bounce: 0.2)) { offset = 0 }
                }
            }
    }

    /// La fila sale por la izquierda y después se borra del almacenamiento local.
    private func remove() {
        isRemoving = true
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        withAnimation(.easeIn(duration: 0.18)) { offset = -width }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            var deleted = false
            withAnimation(.snappy) { deleted = onDelete() }
            if !deleted {
                // No se pudo borrar: la fila vuelve a su lugar.
                withAnimation(.spring(duration: 0.3, bounce: 0.2)) { offset = 0 }
            }
            isRemoving = false
        }
    }
}
