import SwiftUI

@main
struct PlantoApp: App {
    init() {
        PlantNotifications.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
