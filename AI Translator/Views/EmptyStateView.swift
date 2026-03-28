import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .bold()
            Text(message)
                .foregroundStyle(.secondary)
        }
    }
}
