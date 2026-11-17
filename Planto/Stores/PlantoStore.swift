import Foundation
import Observation

@MainActor
@Observable
final class PlantoStore {
    private(set) var plants: [Planto] = []
    private(set) var loadError: String?
    private var completionDates: [String: Date] = [:]

    private let defaults: UserDefaults
    private let storageKey = "planto.plants"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completionDates = defaults.dictionary(forKey: "planto.completionDates") as? [String: Date] ?? [:]
        guard let data = defaults.data(forKey: storageKey) else { return }
        do {
            plants = try JSONDecoder().decode([Planto].self, from: data)
        } catch {
            loadError = "Your saved reminders could not be loaded. Please reopen the app to try again."
        }
    }

    func add(_ plant: Planto) throws {
        var plant = plant
        plant.name = try validatedName(plant.name)
        var updated = plants
        updated.append(plant)
        try persist(updated)
    }

    func update(_ plant: Planto) throws {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else {
            throw StoreError.plantNotFound
        }
        var updated = plants
        updated[index] = plant
        updated[index].name = try validatedName(plant.name)
        try persist(updated)
    }

    func delete(_ plant: Planto) throws {
        try persist(plants.filter { $0.id != plant.id })
    }


    func isCompleted(_ plant: Planto, on date: Date = .now) -> Bool {
        guard let completed = completionDates[plant.id.uuidString] else { return false }
        return Calendar.current.isDate(completed, inSameDayAs: date)
    }

    func toggleCompletion(_ plant: Planto, on date: Date = .now) {
        guard plants.contains(where: { $0.id == plant.id }) else { return }
        if isCompleted(plant, on: date) {
            completionDates.removeValue(forKey: plant.id.uuidString)
        } else {
            completionDates[plant.id.uuidString] = date
        }
        defaults.set(completionDates, forKey: "planto.completionDates")
    }

    func completionDate(for plant: Planto) -> Date? {
        completionDates[plant.id.uuidString]
    }

    private func validatedName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw StoreError.emptyName }
        return trimmed
    }

    private func persist(_ updated: [Planto]) throws {
     
        guard loadError == nil else { throw StoreError.unreadableData }
        let data = try JSONEncoder().encode(updated)
        defaults.set(data, forKey: storageKey)
        plants = updated
    }

    enum StoreError: LocalizedError {
        case emptyName
        case plantNotFound
        case unreadableData

        var errorDescription: String? {
            switch self {
            case .emptyName: "Enter a plant name."
            case .plantNotFound: "This reminder no longer exists."
            case .unreadableData: "Saved reminders could not be loaded. Your existing data has been preserved."
            }
        }
    }
}
