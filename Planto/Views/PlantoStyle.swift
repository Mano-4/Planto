import SwiftUI

enum PlantoStyle {
    static let background = Color("PlantoBackground")
    static let surface = Color("PlantoSurface")
    static let card = Color("PlantoCard")
    static let green = Color("PlantoGreen")
    static let progress = Color("PlantoProgress")
    static let progressTrack = Color("PlantoProgressTrack")
    static let tagBackground = Color("PlantoTagBackground")
    static let divider = Color("PlantoDivider")
    static let listSecondary = Color("PlantoListSecondary")
    static let messageSecondary = Color("PlantoMessageSecondary")
    static let brightGreen = Color("PlantoBrightGreen")
    static let secondary = Color("PlantoSecondary")
    static let primary = Color("PlantoPrimary")
    static let destructive = Color("PlantoDestructive")
    static let mascotBackground = Color("PlantoMascotBackground")
    static let lightTag = Color("PlantoLightTag")
    static let waterTag = Color("PlantoWaterTag")
}

struct PlantsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("My Plants 🌱")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(PlantoStyle.primary)
            Rectangle()
                .fill(PlantoStyle.divider)
                .frame(height: 0.5)
        }
        .padding(.leading, 16)
        .padding(.top, 24)
    }
}

struct AddPlantButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 25, weight: .regular))
                .foregroundStyle(PlantoStyle.primary)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.tint(PlantoStyle.green).interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add plant reminder")
    }
}
