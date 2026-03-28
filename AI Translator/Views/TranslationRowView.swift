import SwiftUI

struct TranslationRowView: View {
    let language: String
    let isSource: Bool
    @Binding var text: String

    var body: some View {
        HStack(alignment: .center) {
            Text(language)
                .foregroundStyle(.secondary)
            TextField("", text: $text, axis: .vertical)
                .disabled(isSource)
        }
    }
}
