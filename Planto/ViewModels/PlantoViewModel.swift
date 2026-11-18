import Foundation
import Observation

@MainActor
@Observable
final class PlantoViewModel {
    var plants: [Planto] { store.plants }
    var loadError: String? { store.loadError }
    var errorMessage = ""
    var showingError = false
    var editingPlant: Planto?
    var notificationPlantID: UUID?

    private let store: PlantoStore
    private let notifications: PlantNotifications?

    init(store: PlantoStore? = nil) {
        self.store = store ?? PlantoStore()
        notifications = store == nil ? .shared : nil
    }

    func add(_ plant: Planto) throws {
        try store.add(plant)
        synchronizeNotifications(requestPermission: true)
    }

    func update(_ plant: Planto) throws {
        try store.update(plant)
        synchronizeNotifications(requestPermission: true)
    }

    func delete(_ plant: Planto) throws {
        try store.delete(plant)
        synchronizeNotifications()
    }

    func deleteReminder(_ plant: Planto) {
        do {
            try delete(plant)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    func toggleCompletion(_ plant: Planto) {
        store.toggleCompletion(plant)
        synchronizeNotifications()
    }

    func isCompleted(_ plant: Planto, on date: Date = .now) -> Bool {
        store.isCompleted(plant, on: date)
    }

    func completedCount(on date: Date = .now) -> Int {
        var count = 0
        for plant in plants {
            if isCompleted(plant, on: date) {
                count += 1
            }
        }
        return count
    }

    func synchronizeNotifications(requestPermission: Bool = false) {
        guard loadError == nil else { return }
        notifications?.synchronize(plants: plants, requestPermission: requestPermission)
    }

}
