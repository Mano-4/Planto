import Foundation
import Observation

@MainActor
@Observable
final class SetReminderViewModel {
    var draft: Planto
    let isEditing: Bool
    var errorMessage = ""
    var showingError = false

    init(plant: Planto? = nil) {
        isEditing = plant != nil
        draft = plant ?? Planto(
            name: "", room: .bedroom, light: .fullSun,
            wateringDays: .everyDay, waterAmount: .ml20To50
        )
    }

    var isNameValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func save(using plants: PlantoViewModel) -> Bool {
        guard isNameValid else {
            errorMessage = "Enter a plant name."
            showingError = true
            return false
        }
        do {
            if isEditing {
                try plants.update(draft)
            } else {
                try plants.add(draft)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            return false
        }
    }

    func delete(using plants: PlantoViewModel) -> Bool {
        guard isEditing else { return false }
        do {
            try plants.delete(draft)
            return true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            return false
        }
    }
}
