import Foundation
import Observation
import UserNotifications

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

    func synchronize(plants: [Planto], requestPermission: Bool) {
        let previous = pendingWork
        pendingWork = Task {
            await previous?.value
            do {
                try await updateReminders(plants: plants, requestPermission: requestPermission)
            } catch {
                message = "Your plant was saved, but its notification could not be scheduled. " + error.localizedDescription
                showingMessage = true
            }
        }
    }

    private func updateReminders(plants: [Planto], requestPermission: Bool) async throws {
        let existing = await center.pendingNotificationRequests()
        await removeDeletedPlantNotifications(plants: plants, pending: existing)
        guard !plants.isEmpty else { return }
        guard try await hasPermission(showMessage: requestPermission) else { return }

        for plant in plants {
            let request = Self.makeRequest(for: plant)
            try await center.add(request)
        }
    }

    private func hasPermission(showMessage: Bool) async throws -> Bool {
        var status = await center.notificationSettings().authorizationStatus
        if status == .notDetermined {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            status = await center.notificationSettings().authorizationStatus
        }
        if status == .authorized || status == .provisional || status == .ephemeral {
            return true
        }
        if showMessage {
            message = "Your plant is saved. Enable notifications for Planto in Settings to receive watering reminders."
            showingMessage = true
        }
        return false
    }

    private func removeDeletedPlantNotifications(plants: [Planto], pending: [UNNotificationRequest]) async {
        var validIDs: [String] = []
        for plant in plants {
            validIDs.append(Self.identifier(for: plant.id))
        }
        var removedIDs: [String] = []
        for request in pending {
            if request.identifier.hasPrefix(Self.prefix) && !validIDs.contains(request.identifier) {
                removedIDs.append(request.identifier)
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: removedIDs)

        removedIDs = []
        let delivered = await center.deliveredNotifications()
        for notification in delivered {
            let id = notification.request.identifier
            if id.hasPrefix(Self.prefix) && !validIDs.contains(id) {
                removedIDs.append(id)
            }
        }
        center.removeDeliveredNotifications(withIdentifiers: removedIDs)
    }

    #if DEBUG
    func sendTestNotification(for plant: Planto) async {
        do {
            activate()
            guard try await hasPermission(showMessage: true) else { return }
            let original = Self.makeRequest(for: plant)
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

    static func makeRequest(for plant: Planto) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Planto"
        content.body = "Hey! let's water your plant"
        content.sound = .default
        content.threadIdentifier = plant.id.uuidString
        content.userInfo = ["plantID": plant.id.uuidString]

        var time = DateComponents()
        time.hour = 14
        time.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
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
            defer { completionHandler() }
            if isDefaultAction, let id {
                selectedPlantID = id
            }
        }
    }
}
