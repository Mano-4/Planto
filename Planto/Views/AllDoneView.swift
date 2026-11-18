import SwiftUI

struct AllDoneView: View {
    let onReview: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Image("PlantMascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 164, height: 200)
                    .frame(width: 219, height: 227, alignment: .top)
                    .background(PlantoStyle.mascotBackground, in: Ellipse())
                    .accessibilityHidden(true)
                    .padding(.top, 127)

                Text("All Done! 🎉")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(PlantoStyle.primary)
                    .padding(.top, 33)

                Button(action: onReview) {
                    Text("All Reminders Completed")
                        .font(.system(size: 16))
                        .foregroundStyle(PlantoStyle.messageSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Show reminders to edit or uncheck a plant")
                .padding(.top, 14)
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
    }
}

#Preview("All Done") {
    VStack(spacing: 0) {
        PlantsHeader()
        AllDoneView(onReview: {})
    }
    .overlay(alignment: .bottomTrailing) {
        AddPlantButton(action: {})
            .padding(.trailing, 30)
            .padding(.bottom, 7)
    }
    .background(PlantoStyle.background)
    .preferredColorScheme(.dark)
}
