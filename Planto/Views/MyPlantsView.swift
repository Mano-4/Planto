import SwiftUI

struct MyPlantsView: View {
    @EnvironmentObject private var store: PlantoStore
    @State private var editingPlant: Planto?
    @State private var reviewingCompleted = false
    @State private var errorMessage = ""
    @State private var showingError = false
    let onAdd: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let completedCount = store.plants.filter { store.isCompleted($0, on: context.date) }.count

            ZStack(alignment: .bottomTrailing) {
                if store.plants.isEmpty {
                    EmptyRemindersView()
                } else if completedCount == store.plants.count && !reviewingCompleted {
                    AllDoneView(onReview: { reviewingCompleted = true })
                } else {
                    VStack(spacing: 0) {
                        PlantProgressView(completed: completedCount, total: store.plants.count)
                            .padding(.top, 33)
                            .padding(.bottom, 50)

                        List {
                            ForEach(store.plants) { plant in
                                PlantReminderRow(
                                    plant: plant,
                                    isCompleted: store.isCompleted(plant, on: context.date),
                                    onToggle: {
                                        store.toggleCompletion(plant)
                                        reviewingCompleted = false
                                    },
                                    onEdit: { editingPlant = plant }
                                )
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                .listRowBackground(PlantoStyle.background)
                                .listRowSeparator(.hidden)
                                .swipeActions {
                                    Button("Delete", role: .destructive) {
                                        do {
                                            try store.delete(plant)
                                        } catch {
                                            errorMessage = error.localizedDescription
                                            showingError = true
                                        }
                                    }
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
                    .padding(.trailing, 30)
                    .padding(.bottom, 7)
            }
        }
        .sheet(item: $editingPlant) { plant in
            SetReminderView(plant: plant)
                .environmentObject(store)
        }
        .alert("Unable to Delete", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
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
                    .fill(PlantoStyle.card)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(PlantoStyle.brightGreen)
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
                            .strokeBorder(isCompleted ? PlantoStyle.brightGreen : PlantoStyle.secondary, lineWidth: 1)
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
                            .foregroundStyle(PlantoStyle.secondary)
                        Text(plant.name)
                            .font(.system(size: 28))
                            .foregroundStyle(isCompleted ? PlantoStyle.secondary : PlantoStyle.primary)
                        HStack(spacing: 10) {
                            PlantTag(text: plant.light.rawValue, symbol: "sun.max", color: Color(red: 0.67, green: 0.62, blue: 0.34))
                            PlantTag(text: plant.waterAmount.rawValue, symbol: "drop", color: Color(red: 0.62, green: 0.79, blue: 0.84))
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
                .fill(PlantoStyle.card)
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
            .background(PlantoStyle.surface, in: RoundedRectangle(cornerRadius: 7))
    }
}

#Preview("My Plants") {
    MyPlantsPreview()
}

private struct MyPlantsPreview: View {
    @StateObject private var store: PlantoStore

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
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        VStack(spacing: 0) {
            PlantsHeader()
            MyPlantsView(onAdd: {})
        }
        .environmentObject(store)
        .background(PlantoStyle.background)
        .preferredColorScheme(.dark)
    }
}
