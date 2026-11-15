import Foundation
import Observation

@MainActor
@Observable
final class PlantoViewModel {
    private(set) var plants: [Planto] = []
    private(set) var loadError: String?
    var errorMessage = ""
    var showingError = false

    private var completionDates: [UUID: Date] = [:]
    private let store: PlantoStore

    init(store: PlantoStore? = nil) {
        self.store = store ?? PlantoStore()
        refresh()
    }

    func add(_ plant: Planto) throws {
        try store.add(plant)
        refresh()
    }

    func update(_ plant: Planto) throws {
        try store.update(plant)
        refresh()
    }

    func delete(_ plant: Planto) throws {
        try store.delete(plant)
        refresh()
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
        refresh()
    }

    func isCompleted(_ plant: Planto, on date: Date = .now) -> Bool {
        guard let completedAt = completionDates[plant.id] else { return false }
        return Calendar.current.isDate(completedAt, inSameDayAs: date)
    }

    func completedCount(on date: Date = .now) -> Int {
        plants.filter { isCompleted($0, on: date) }.count
    }

    private func refresh() {
        plants = store.plants
        loadError = store.loadError
        completionDates = Dictionary(uniqueKeysWithValues: plants.compactMap { plant in
            store.completionDate(for: plant).map { (plant.id, $0) }
        })
    }
}
