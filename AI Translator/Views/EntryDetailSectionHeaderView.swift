import SwiftUI

struct EntryDetailSectionHeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .bold()
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .accessibilityAddTraits(.isHeader)
    }
}
