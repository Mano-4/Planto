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

        for plant in plants {
            let request = Self.makeRequest(for: plant, wateredAt: completionDates[plant.id])
            // Do not restart the countdown on launch or when another plant changes.
            if let current = existing.first(where: { $0.identifier == request.identifier }),
               current.content.userInfo["schedule"] as? String == request.content.userInfo["schedule"] as? String {
                continue
            }
            try await center.add(request)
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

    static func makeRequest(for plant: Planto, wateredAt: Date?) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Planto"
        content.body = "Hey! let's water your plant"
        content.sound = .default
        content.threadIdentifier = plant.id.uuidString
        // Include the name so edits also refresh pending notification metadata.
        content.userInfo = [
            "plantID": plant.id.uuidString,
            "schedule": "\(plant.name)|\(plant.wateringDays.rawValue)|\(wateredAt?.timeIntervalSince1970 ?? 0)"
        ]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: plant.wateringDays.interval, repeats: true)
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
