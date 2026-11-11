import SwiftUI

struct SetReminderView: View {
    @EnvironmentObject private var store: PlantoStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("planto.hasStarted") private var hasStarted = false
    @State private var draft: Planto
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var confirmingDelete = false

    private let isEditing: Bool

    init(plant: Planto? = nil) {
        isEditing = plant != nil
        _draft = State(initialValue: plant ?? Planto(
            name: "", room: .bedroom, light: .fullSun,
            wateringDays: .everyDay, waterAmount: .ml20To50
        ))
    }

    private var isNameValid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ReminderNavigationBar(canSave: isNameValid, onClose: { dismiss() }, onSave: save)
                .padding(.horizontal, 24)
                .padding(.top, 14)

            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Text("Plant Name")
                            .foregroundStyle(PlantoStyle.primary)
                        TextField("Pothos", text: $draft.name)
                            .foregroundStyle(PlantoStyle.secondary)
                            .tint(PlantoStyle.brightGreen)
                            .submitLabel(.done)
                            .onSubmit { if isNameValid { save() } }
                            .accessibilityLabel("Plant Name")
                    }
                    .font(.system(size: 18))
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .background(PlantoStyle.card, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.top, 54)

                    VStack(spacing: 0) {
                        ReminderPicker(title: "Room", symbol: "location", selection: $draft.room)
                        Divider().padding(.leading, 16)
                        ReminderPicker(title: "Light", symbol: "sun.max", selection: $draft.light)
                    }
                    .background(PlantoStyle.card, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.top, 50)

                    VStack(spacing: 0) {
                        ReminderPicker(title: "Watering Days", symbol: "drop", selection: $draft.wateringDays)
                        Divider().padding(.leading, 16)
                        ReminderPicker(title: "Water", symbol: "drop", selection: $draft.waterAmount)
                    }
                    .background(PlantoStyle.card, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.top, 40)

                    if isEditing {
                        Button("Delete Reminder", role: .destructive) {
                            confirmingDelete = true
                        }
                        .font(.system(size: 17))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(PlantoStyle.card, in: Capsule())
                        .padding(.horizontal, 8)
                        .padding(.top, 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .background(PlantoStyle.surface.ignoresSafeArea())
        .presentationBackground(PlantoStyle.surface)
        .presentationCornerRadius(40)
        .presentationDragIndicator(.hidden)
        .preferredColorScheme(.dark)
        .alert("Unable to Save Changes", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog("Delete this reminder?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Reminder", role: .destructive, action: delete)
            Button("Cancel", role: .cancel) { }
        }
    }

    private func save() {
        do {
            if isEditing {
                try store.update(draft)
            } else {
                try store.add(draft)
            }
            hasStarted = true
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func delete() {
        do {
            try store.delete(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

private struct ReminderNavigationBar: View {
    let canSave: Bool
    let onClose: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(PlantoStyle.card, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
            }
            .accessibilityLabel("Cancel")
            Spacer()
            Button(action: onSave) {
                Image(systemName: "checkmark")
                    .font(.system(size: 25, weight: .medium))
                    .frame(width: 44, height: 44)
                    .background(PlantoStyle.green, in: Circle())
                    .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
                    .opacity(canSave ? 1 : 0.5)
            }
            .disabled(!canSave)
            .accessibilityLabel("Save reminder")
            .accessibilityHint(canSave ? "Save and close" : "Enter a plant name first")
        }
        .overlay {
            Text("Set Reminder")
                .font(.system(size: 17, weight: .semibold))
                .allowsHitTesting(false)
        }
        .buttonStyle(.plain)
        .foregroundStyle(PlantoStyle.primary)
    }
}

private struct ReminderPicker<Option>: View
where Option: CaseIterable & Identifiable & Hashable & RawRepresentable,
      Option.RawValue == String {
    let title: LocalizedStringKey
    let symbol: String
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .frame(width: 20)
            Text(title)
            Spacer(minLength: 4)
            Picker(title, selection: $selection) {
                ForEach(Array(Option.allCases)) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .tint(PlantoStyle.secondary)
        }
        .font(.system(size: 18))
        .foregroundStyle(PlantoStyle.primary)
        .padding(.horizontal, 16)
        .frame(height: 47)
    }
}

#Preview("Set Reminder") {
    SetReminderView()
        .environmentObject(PlantoStore())
}
