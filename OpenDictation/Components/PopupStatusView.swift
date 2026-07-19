import SwiftUI

/// Icon + title + caption + action row: the shared skeleton of the recorder
/// popup's terminal states (failure, permission guidance).
struct PopupStatusView<Actions: View>: View {
    let systemImage: String
    let iconColor: Color
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.14), in: Circle())
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                actions
            }
            .padding(.top, 4)
        }
    }
}
