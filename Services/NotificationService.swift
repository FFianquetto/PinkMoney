import Combine
import Foundation
import UserNotifications

@MainActor
final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func checkBudgetThreshold(currentTotal: Double, limit: Double) {
        guard limit > 0 else { return }
        let ratio = currentTotal / limit
        let storageKey = "pinkmoney.alert.\(Self.monthKey())"
        let defaults = UserDefaults.standard

        if ratio < 0.9 {
            defaults.set(0, forKey: storageKey)
            return
        }

        let level = ratio >= 1 ? 100 : 90
        let previous = defaults.integer(forKey: storageKey)
        guard level > previous else { return }
        defaults.set(level, forKey: storageKey)

        let body = level == 100
            ? "¡Cuidado! Ya rebasaste tu límite mensual."
            : "¡Cuidado! Estás a punto de rebasar tu límite mensual"
        schedule(
            title: "El Cerdo avisa del límite",
            body: body,
            identifier: "pinkmoney.limit.\(Self.monthKey()).\(level)"
        )
    }

    func resetBudgetAlerts() {
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("pinkmoney.alert.") {
            defaults.removeObject(forKey: key)
        }
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    private func schedule(title: String, body: String, identifier: String) {
        Task {
            await requestAuthorizationIfNeeded()
            let settings = await center.notificationSettings()
            let allowed: Set<UNAuthorizationStatus> = [.authorized, .provisional, .ephemeral]
            guard allowed.contains(settings.authorizationStatus) else { return }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
            try? await center.add(request)
        }
    }

    private static func monthKey(date: Date = .now) -> String {
        let parts = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)"
    }
}
