import SwiftUI

enum PlantoStyle {
    static let background = Color.black
    static let surface = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255)
    static let card = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)
    static let green = Color(red: 38 / 255, green: 195 / 255, blue: 145 / 255)
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
                .fill(PlantoStyle.card)
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
                .background(PlantoStyle.green, in: Circle())
                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add plant reminder")
    }
}
