import Foundation
import Observation
import UserNotifications

extension WateringDays {
    var interval: TimeInterval {
        let days: Int
        switch self {
        case .everyDay: days = 1
        case .every2Days: days = 2
        case .every3Days: days = 3
        case .onceAWeek: days = 7
        case .every10Days: days = 10
        case .every2Weeks: days = 14
        }
        return TimeInterval(days * 24 * 60 * 60)
    }
}

@MainActor
@Observable
final class PlantNotifications: NSObject, UNUserNotificationCenterDelegate {
    static let shared = PlantNotifications()

    var selectedPlantID: UUID?
    var message = ""
    var showingMessage = false

    private let center = UNUserNotificationCenter.current()
    private var pendingWork: Task<Void, Never>?
    private static let prefix = "planto.watering."

    func activate() {
        center.delegate = self
    }

    // Serialize snapshots so a slow permission prompt cannot restore a deleted reminder.
    func synchronize(plants: [Planto], completionDates: [UUID: Date], requestPermission: Bool) {
        let previous = pendingWork
        pendingWork = Task {
            await previous?.value
            do {
                try await reconcile(plants: plants, completionDates: completionDates, requestPermission: requestPermission)
            } catch {
                message = "Your plant was saved, but its notification could not be scheduled. " + error.localizedDescription
                showingMessage = true
            }
        }
    }

    private func reconcile(plants: [Planto], completionDates: [UUID: Date], requestPermission: Bool) async throws {
        let existing = await center.pendingNotificationRequests()
        let validIDs = Set(plants.map { Self.identifier(for: $0.id) })
        let obsolete = existing.map(\.identifier).filter { $0.hasPrefix(Self.prefix) && !validIDs.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: obsolete)
        let delivered = await center.deliveredNotifications()
        center.removeDeliveredNotifications(withIdentifiers: delivered.map { $0.request.identifier }
            .filter { $0.hasPrefix(Self.prefix) && !validIDs.contains($0) })

        guard !plants.isEmpty else { return }
        var status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            status = await center.notificationSettings().authorizationStatus
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            if requestPermission {
                message = "Your plant is saved. Enable notifications for Planto in Settings to receive watering reminders."
                showingMessage = true
            }
            return
        }

        let defaults = UserDefaults.standard
        var anchors = defaults.dictionary(forKey: "planto.notificationAnchors") as? [String: Date] ?? [:]
        var submitted = defaults.dictionary(forKey: "planto.notificationCycles") as? [String: String] ?? [:]
        let plantIDs = Set(plants.map { $0.id.uuidString })
        anchors = anchors.filter { plantIDs.contains($0.key) }
        submitted = submitted.filter { plantIDs.contains($0.key) }
        for plant in plants {
            let key = plant.id.uuidString
            let current = existing.first { $0.identifier == Self.identifier(for: plant.id) }
            if anchors[key] == nil {
                // Preserve an existing countdown when migrating from interval reminders.
                let next = (current?.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
                anchors[key] = next?.addingTimeInterval(-plant.wateringDays.interval) ?? .now
            }
            defaults.set(anchors, forKey: "planto.notificationAnchors")
            let anchor = completionDates[plant.id] ?? anchors[key] ?? .now
            let due = Self.nextWateringDate(for: plant, anchor: anchor)
            let request = Self.makeRequest(for: plant, wateredAt: anchor)
            let cycle = request.content.userInfo["schedule"] as? String
            // A delivered/dismissed overdue reminder must not reappear every app launch.
            if current == nil, due <= .now, submitted[key] == cycle { continue }
            // Do not restart the countdown on launch or when another plant changes.
            if let current = existing.first(where: { $0.identifier == request.identifier }),
               current.content.userInfo["schedule"] as? String == request.content.userInfo["schedule"] as? String {
                continue
            }
            try await center.add(request)
            submitted[key] = cycle
            defaults.set(submitted, forKey: "planto.notificationCycles")
            center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
        }
    }

    #if DEBUG
    func sendTestNotification(for plant: Planto) async {
        do {
            activate()
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                message = "Enable notifications for Planto in Settings, then try again."
                showingMessage = true
                return
            }
            let original = Self.makeRequest(for: plant, wateredAt: nil)
            let request = UNNotificationRequest(
                identifier: "planto.notification-test",
                content: original.content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            )
            try await center.add(request)
        } catch {
            message = error.localizedDescription
            showingMessage = true
        }
    }
    #endif

    static func identifier(for id: UUID) -> String {
        prefix + id.uuidString
    }

    static func nextWateringDate(for plant: Planto, anchor: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: Int(plant.wateringDays.interval / 86_400), to: anchor)
            ?? anchor.addingTimeInterval(plant.wateringDays.interval)
    }

    static func makeRequest(for plant: Planto, wateredAt: Date?) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Planto"
        content.body = "Hey! let's water your plant"
        content.sound = .default
        content.threadIdentifier = plant.id.uuidString
        content.userInfo = [
            "plantID": plant.id.uuidString,
            "schedule": "v2|\(plant.wateringDays.rawValue)|\(wateredAt?.timeIntervalSince1970 ?? 0)"
        ]
        let due = nextWateringDate(for: plant, anchor: wateredAt ?? .now)
        let fireDate = max(due, Date.now.addingTimeInterval(1))
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        components.calendar = Calendar.current
        components.timeZone = Calendar.current.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier(for: plant.id), content: content, trigger: trigger)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let isDefaultAction = response.actionIdentifier == UNNotificationDefaultActionIdentifier
        let value = response.notification.request.content.userInfo["plantID"] as? String
        let id = value.flatMap(UUID.init(uuidString:))
        Task { @MainActor in
            // UIKit's notification response completion must also run on the main thread.
            defer { completionHandler() }
            if isDefaultAction, let id {
                selectedPlantID = id
            }
        }
    }
}
