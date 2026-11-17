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

    func synchronize(plants: [Planto], completionDates: [UUID: Date], requestPermission: Bool) {
        let previous = pendingWork
        pendingWork = Task {
            await previous?.value
            do {
                try await updateReminders(plants: plants, completionDates: completionDates, requestPermission: requestPermission)
            } catch {
                message = "Your plant was saved, but its notification could not be scheduled. " + error.localizedDescription
                showingMessage = true
            }
        }
    }

    private func updateReminders(plants: [Planto], completionDates: [UUID: Date], requestPermission: Bool) async throws {
        let existing = await center.pendingNotificationRequests()
        await removeDeletedPlantNotifications(plants: plants, pending: existing)
        guard !plants.isEmpty else { return }
        guard try await hasPermission(showMessage: requestPermission) else { return }

     
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
                let next = (current?.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
                anchors[key] = next?.addingTimeInterval(-plant.wateringDays.interval) ?? .now
            }
            defaults.set(anchors, forKey: "planto.notificationAnchors")
            let anchor = completionDates[plant.id] ?? anchors[key] ?? .now
            let due = Self.nextWateringDate(for: plant, anchor: anchor)
            let request = Self.makeRequest(for: plant, wateredAt: anchor)
            let cycle = request.content.userInfo["schedule"] as? String
          
            if current == nil, due <= .now, submitted[key] == cycle { continue }
            if let current, current.content.userInfo["schedule"] as? String == cycle {
                continue
            }
            try await center.add(request)
            submitted[key] = cycle
            defaults.set(submitted, forKey: "planto.notificationCycles")
            center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
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
        Calendar.current.date(byAdding: .day, value: plant.wateringDays.numberOfDays, to: anchor)
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
            defer { completionHandler() }
            if isDefaultAction, let id {
                selectedPlantID = id
            }
        }
    }
}
