import SwiftUI

struct ContentView: View {
    @State private var viewModel = PlantoViewModel()
    @AppStorage("planto.hasStarted") private var hasStarted = false
    @State private var showingReminder = false

    var body: some View {
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
        .sheet(isPresented: $showingReminder) {
            SetReminderView()
                .environment(viewModel)
        }
        .environment(viewModel)
    }
}
