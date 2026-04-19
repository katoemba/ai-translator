import SwiftUI

struct SettingsView: View {
    @AppStorage("openaiToken") private var openAIToken = ""
    @AppStorage("openaiContext") private var openAIContext = ""

    var body: some View {
        Form {
            Section {
                SecureField("API token", text: $openAIToken)
                    .textFieldStyle(.automatic)
                Text("Your token is stored locally on this Mac.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(alignment: .top) {
                    Text("Context:")
                    
                    TextEditor(text: $openAIContext)
                        .frame(minHeight: 120)
                        .multilineTextAlignment(.leading)
                }
                Text("Add domain notes, tone, or glossary hints for the translator.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                EntryDetailSectionHeaderView(title: "OpenAI")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
