import SwiftUI

struct SettingsView: View {
    @AppStorage("openaiToken") private var openAIToken = ""

    var body: some View {
        Form {
            Section {
                SecureField("API token", text: $openAIToken)
                    .textFieldStyle(.roundedBorder)
                Text("Your token is stored locally on this Mac.")
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
