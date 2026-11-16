import SwiftUI

struct ContentView: View {
    @State private var viewModel = PlantoViewModel()
    @AppStorage("planto.hasStarted") private var hasStarted = false
    @State private var showingReminder = false
    @State private var notifications = PlantNotifications.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var notifications = notifications
        VStack(alignment: .leading, spacing: 0) {
            PlantsHeader()

            if let loadError = viewModel.loadError {
                Text(loadError)
                    .foregroundStyle(.red)
                    .padding()
            }

            if hasStarted || !viewModel.plants.isEmpty {
                MyPlantsView(onAdd: { showingReminder = true })
            } else {
                WelcomeView(onSetReminder: { showingReminder = true })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .tint(PlantoStyle.green)
        .sheet(isPresented: $showingReminder, onDismiss: openNotification) {
            SetReminderView()
                .environment(viewModel)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { viewModel.synchronizeNotifications() }
        }
        .onChange(of: notifications.selectedPlantID, initial: true) { _, _ in
            openNotification()
        }
        .alert("Watering Notifications", isPresented: $notifications.showingMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(notifications.message)
        }
        .environment(viewModel)
    }
    private func openNotification() {
        guard let id = notifications.selectedPlantID else { return }
        if showingReminder {
            showingReminder = false
            return // Route after the add sheet has finished dismissing.
        }
        viewModel.editingPlant = viewModel.plants.first { $0.id == id }
        notifications.selectedPlantID = nil
    }

}
