import SwiftUI

struct EmptyRemindersView: View {
    var body: some View {
        VStack {
            Text("No reminders set yet..")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PlantoStyle.secondary)
                .padding(.top, 307)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("No Reminders") {
    VStack(spacing: 0) {
        PlantsHeader()
        EmptyRemindersView()
    }
    .overlay(alignment: .bottomTrailing) {
        AddPlantButton(action: {})
            .padding(.trailing, 30)
            .padding(.bottom, 7)
    }
    .background(PlantoStyle.background)
    .preferredColorScheme(.dark)
}
