import SwiftUI

struct AddLanguageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var languageCode = ""
    let onAdd: (String) -> Void

    var body: some View {
        VStack {
            Text("Add Language")
                .font(.title2)
                .bold()

            TextField("Language code (e.g. fr, de)", text: $languageCode)

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Button("Add") {
                    onAdd(languageCode)
                    dismiss()
                }
                .disabled(languageCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}
