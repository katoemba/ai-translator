import SwiftUI

struct SettingsView: View {
    @AppStorage("openaiToken") private var openAIToken = ""
    @AppStorage("openaiContext") private var openAIContext = ""
    @AppStorage("openaiModel") private var openAIModel = "gpt-4.1"

    private let availableModels = [
        "gpt-5.4",
        "gpt-5.4-mini",
        "gpt-5.4-nano",
        "gpt-4.1",
        "gpt-4.1-mini",
        "gpt-4.1-nano",
        "gpt-4o-mini"
    ]

    var body: some View {
        let models = availableModels.contains(openAIModel) ? availableModels : availableModels + [openAIModel]

        Form {
            Section {
                SecureField("API token", text: $openAIToken)
                    .textFieldStyle(.automatic)
                Text("Your token is stored locally on this Mac.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker("Model", selection: $openAIModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                Text("Choose the model used for translations. Larger models prioritize accuracy; Mini/Nano prioritize speed and lower cost.")
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
