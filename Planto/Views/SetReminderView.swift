import SwiftUI

struct SetReminderView: View {
    @Environment(PlantoViewModel.self) private var plants
    @Environment(\.dismiss) private var dismiss
    @AppStorage("planto.hasStarted") private var hasStarted = false
    @State private var viewModel: SetReminderViewModel
    @State private var confirmingDelete = false

    init(plant: Planto? = nil) {
        _viewModel = State(initialValue: SetReminderViewModel(plant: plant))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(spacing: 0) {
            ReminderNavigationBar(canSave: viewModel.isNameValid, onClose: { dismiss() }, onSave: save)
                .padding(.horizontal, 24)
                .padding(.top, 14)

            ScrollView {
                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Text("Plant Name")
                            .foregroundStyle(PlantoStyle.primary)
                        TextField("Pothos", text: $viewModel.draft.name)
                            .foregroundStyle(PlantoStyle.secondary)
                            .tint(PlantoStyle.brightGreen)
                            .submitLabel(.done)
                            .onSubmit { if viewModel.isNameValid { save() } }
                            .accessibilityLabel("Plant Name")
                    }
                    .font(.system(size: 18))
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .background(PlantoStyle.card, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.top, 54)

                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "location").frame(width: 20)
                            Text("Room")
                            Spacer(minLength: 4)
                            Picker("Room", selection: $viewModel.draft.room) {
                                ForEach(Room.allCases) { option in
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
                        Divider().padding(.leading, 16)
                        HStack(spacing: 6) {
                            Image(systemName: "sun.max").frame(width: 20)
                            Text("Light")
                            Spacer(minLength: 4)
                            Picker("Light", selection: $viewModel.draft.light) {
                                ForEach(Light.allCases) { option in
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
                    .background(PlantoStyle.card, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.top, 50)

                    VStack(spacing: 0) {
                        HStack(spacing: 6) {
                            Image(systemName: "drop").frame(width: 20)
                            Text("Watering Days")
                            Spacer(minLength: 4)
                            Picker("Watering Days", selection: $viewModel.draft.wateringDays) {
                                ForEach(WateringDays.allCases) { option in
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
                        Divider().padding(.leading, 16)
                        HStack(spacing: 6) {
                            Image(systemName: "drop").frame(width: 20)
                            Text("Water")
                            Spacer(minLength: 4)
                            Picker("Water", selection: $viewModel.draft.waterAmount) {
                                ForEach(WaterAmount.allCases) { option in
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
                    .background(PlantoStyle.card, in: RoundedRectangle(cornerRadius: 30))
                    .padding(.top, 40)

                    if viewModel.isEditing {
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
        .alert("Unable to Save Changes", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .confirmationDialog("Delete this reminder?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete Reminder", role: .destructive, action: delete)
            Button("Cancel", role: .cancel) { }
        }
    }

    private func save() {
        if viewModel.save(using: plants) {
            hasStarted = true
            dismiss()
        }
    }

    private func delete() {
        if viewModel.delete(using: plants) {
            dismiss()
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
                    .glassEffect(.regular.interactive(), in: Circle())
            }
            .accessibilityLabel("Cancel")
            Spacer()
            Button(action: onSave) {
                Image(systemName: "checkmark")
                    .font(.system(size: 25, weight: .medium))
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular.tint(PlantoStyle.green).interactive(canSave), in: Circle())
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

#Preview("Set Reminder") {
    SetReminderView()
        .environment(PlantoViewModel())
}
