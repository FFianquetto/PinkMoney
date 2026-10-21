import Foundation

enum PinkMoneyError: LocalizedError {
    case invalidEmail
    case weakPassword
    case invalidAmount
    case invalidBudget
    case invalidName
    case invalidSchool
    case offline
    case unauthorized
    case missingDocument
    case localStore(String)
    case network
    case firebase(String)
    case message(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            "Escribe un correo válido."
        case .weakPassword:
            "La contraseña debe tener al menos 6 caracteres."
        case .invalidAmount:
            "Escribe un monto válido: mayor a cero y hasta $1,000,000."
        case .invalidBudget:
            "El presupuesto debe ser mayor a cero y de hasta $1,000,000."
        case .invalidName:
            "Escribe tu nombre (hasta 40 caracteres)."
        case .invalidSchool:
            "El nombre de la escuela es muy largo (máximo 60 caracteres)."
        case .offline:
            "Sin internet. El Cerdo no puede validar con Firebase ahora."
        case .unauthorized:
            "La sesión expiró. Entra de nuevo."
        case .missingDocument:
            "No se encontró el registro en la nube."
        case .localStore(let detail):
            "No se pudo escribir la base local. \(detail)"
        case .network:
            "No hay conexión con Firebase. Lo guardado sigue en este iPhone."
        case .firebase(let message):
            message
        case .message(let message):
            message
        }
    }
}
