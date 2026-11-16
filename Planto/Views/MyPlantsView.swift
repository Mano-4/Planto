import SwiftUI

struct MyPlantsView: View {
    @Environment(PlantoViewModel.self) private var viewModel
    @State private var reviewingCompleted = false
    let onAdd: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let completedCount = viewModel.completedCount(on: context.date)

            ZStack(alignment: .bottomTrailing) {
                if viewModel.plants.isEmpty {
                    EmptyRemindersView()
                } else if completedCount == viewModel.plants.count && !reviewingCompleted {
                    AllDoneView(onReview: { reviewingCompleted = true })
                } else {
                    VStack(spacing: 0) {
                        PlantProgressView(completed: completedCount, total: viewModel.plants.count)
                            .padding(.top, 33)
                            .padding(.bottom, 50)

                        List {
                            ForEach(viewModel.plants) { plant in
                                PlantReminderRow(
                                    plant: plant,
                                    isCompleted: viewModel.isCompleted(plant, on: context.date),
                                    onToggle: {
                                        viewModel.toggleCompletion(plant)
                                        reviewingCompleted = false
                                    },
                                    onEdit: { viewModel.editingPlant = plant }
                                )
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                .listRowBackground(PlantoStyle.background)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.deleteReminder(plant)
                                    } label: {
                                        Label("Delete Reminder", systemImage: "trash")
                                            .labelStyle(.iconOnly)
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .contentMargins(.top, 0)
                        .padding(.bottom, 60)
                    }
                }

                AddPlantButton(action: onAdd)
                    #if DEBUG
                    .contextMenu {
                        if let plant = viewModel.plants.first {
                            Button("Test Notification (5 seconds)", systemImage: "bell") {
                                Task {
                                    await PlantNotifications.shared.sendTestNotification(for: plant)
                                }
                            }
                        }
                    }
                    #endif
                    .padding(.trailing, 30)
                    .padding(.bottom, 7)
            }
        }
        .sheet(item: $viewModel.editingPlant) { plant in
            SetReminderView(plant: plant)
                .environment(viewModel)
        }
        .alert("Unable to Delete", isPresented: $viewModel.showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

private struct PlantProgressView: View {
    let completed: Int
    let total: Int

    var body: some View {
        VStack(spacing: 15) {
            if completed == 0 {
                Text("Your plants are waiting for a sip 💦")
                    .font(.system(size: 18))
            } else {
                Text("\(completed) of your plants feel loved today✨")
                    .font(.system(size: 18))
            }
            GeometryReader { geometry in
                Capsule()
                    .fill(PlantoStyle.progressTrack)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(PlantoStyle.progress)
                            .frame(width: geometry.size.width * CGFloat(completed) / CGFloat(max(total, 1)))
                    }
            }
            .frame(height: 8)
            .accessibilityLabel("Plants cared for today")
            .accessibilityValue("\(completed) of \(total)")
        }
        .foregroundStyle(PlantoStyle.primary)
        .padding(.horizontal, 34)
    }
}

private struct PlantReminderRow: View {
    let plant: Planto
    let isCompleted: Bool
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onToggle) {
                    ZStack {
                        Circle()
                            .strokeBorder(isCompleted ? PlantoStyle.brightGreen : PlantoStyle.listSecondary, lineWidth: 1)
                        if isCompleted {
                            Circle().fill(PlantoStyle.brightGreen)
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.black)
                        }
                    }
                    .frame(width: 25, height: 25)
                    .frame(width: 30, height: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark \(plant.name) \(isCompleted ? "incomplete" : "complete")")
                .accessibilityValue(isCompleted ? "Completed" : "Not completed")

                Button(action: onEdit) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 13))
                            Text("in \(plant.room.rawValue)")
                        }
                            .font(.system(size: 15))
                            .foregroundStyle(PlantoStyle.listSecondary)
                        Text(plant.name)
                            .font(.system(size: 28))
                            .foregroundStyle(isCompleted ? PlantoStyle.listSecondary : PlantoStyle.primary)
                        HStack(spacing: 10) {
                            PlantTag(text: plant.light.rawValue, symbol: "sun.max", color: Color(red: 148 / 255, green: 144 / 255, blue: 100 / 255))
                            PlantTag(text: plant.waterAmount.rawValue, symbol: "drop", color: Color(red: 146 / 255, green: 174 / 255, blue: 181 / 255))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Edit reminder")
            }
            .padding(.vertical, 12)

            Rectangle()
                .fill(PlantoStyle.divider)
                .frame(height: 0.5)
        }
    }
}

private struct PlantTag: View {
    let text: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 13))
            Text(text)
        }
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(PlantoStyle.tagBackground, in: RoundedRectangle(cornerRadius: 7))
    }
}

#Preview("My Plants") {
    MyPlantsPreview()
}

private struct MyPlantsPreview: View {
    @State private var viewModel: PlantoViewModel

    init() {
        guard let defaults = UserDefaults(suiteName: "planto.visualPreview") else {
            preconditionFailure("Unable to create isolated preview storage")
        }
        defaults.removeObject(forKey: "planto.plants")
        defaults.removeObject(forKey: "planto.completionDates")
        let store = PlantoStore(defaults: defaults)
        for (name, room) in [("Monstera", Room.kitchen), ("Pothos", .bedroom), ("Orchid", .livingRoom), ("Spider", .kitchen)] {
            let plant = Planto(name: name, room: room, light: .fullSun, wateringDays: .everyDay, waterAmount: .ml20To50)
            try? store.add(plant)
            if name != "Monstera" { store.toggleCompletion(plant) }
        }
        _viewModel = State(initialValue: PlantoViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            PlantsHeader()
            MyPlantsView(onAdd: {})
        }
        .environment(viewModel)
        .background(PlantoStyle.background)
        .preferredColorScheme(.dark)
    }
}
