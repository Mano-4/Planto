import SwiftUI

enum PlantoStyle {
    static let background = Color.black
    static let surface = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let card = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
    // Sampled from the rendered Sketch reference; controls differ from the mascot green.
    static let green = Color(red: 41 / 255, green: 118 / 255, blue: 95 / 255)
    static let progress = Color(red: 89 / 255, green: 166 / 255, blue: 143 / 255)
    static let progressTrack = Color(red: 38 / 255, green: 38 / 255, blue: 38 / 255)
    static let tagBackground = Color(red: 24 / 255, green: 24 / 255, blue: 29 / 255)
    static let divider = Color(red: 34 / 255, green: 34 / 255, blue: 36 / 255)
    static let listSecondary = Color(red: 152 / 255, green: 152 / 255, blue: 152 / 255)
    static let messageSecondary = Color(red: 145 / 255, green: 145 / 255, blue: 133 / 255)
    static let brightGreen = Color(red: 40 / 255, green: 224 / 255, blue: 168 / 255)
    static let secondary = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    static let primary = Color.white
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
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.tint(PlantoStyle.green).interactive(), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add plant reminder")
    }
}
