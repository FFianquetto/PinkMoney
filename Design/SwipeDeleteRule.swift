import CoreGraphics

/// Regla de "deslizar para borrar": cuándo un deslizamiento a la izquierda borra y cuándo se cancela.
enum SwipeDeleteRule {
    enum Outcome: Equatable {
        case delete
        case cancel
    }

    /// Distancia mínima para borrar: 40 % del ancho de la fila, nunca menos de 110 puntos.
    static func threshold(width: CGFloat) -> CGFloat {
        max(110, width * 0.4)
    }

    /// - Parameters:
    ///   - translation: desplazamiento horizontal al soltar (negativo = izquierda).
    ///   - predictedEnd: dónde terminaría el dedo por la velocidad del gesto.
    ///   - width: ancho de la fila.
    static func outcome(translation: CGFloat, predictedEnd: CGFloat, width: CGFloat) -> Outcome {
        let distance = -translation
        if distance >= threshold(width: width) { return .delete }
        // Un deslizamiento rápido también borra, siempre que ya haya recorrido un tramo.
        if distance >= 60, -predictedEnd >= width * 0.8 { return .delete }
        return .cancel
    }
}
