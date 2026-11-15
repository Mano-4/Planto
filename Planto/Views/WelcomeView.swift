import SwiftUI

struct WelcomeView: View {
    let onSetReminder: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("PlantMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 164, height: 200)
                    .accessibilityHidden(true)
                    .padding(.top, 77)

                Text("Start your plant journey!")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(PlantoStyle.primary)
                    .padding(.top, 37)

                Text("Now all your plants will be in one place and we will help you take care of them :)🪴")
                    .font(.system(size: 16))
                    .foregroundStyle(PlantoStyle.messageSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 315)
                    .padding(.top, 25)

                Button(action: onSetReminder) {
                    Text("Set Plant Reminder")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 280, height: 42)
                        .background(PlantoStyle.buttonFill, in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, 105)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview("Welcome") {
    VStack(spacing: 0) {
        PlantsHeader()
        WelcomeView(onSetReminder: {})
    }
    .background(PlantoStyle.background)
    .preferredColorScheme(.dark)
}
