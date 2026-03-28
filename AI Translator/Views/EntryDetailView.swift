import SwiftUI

struct EntryDetailView: View {
    @Bindable var model: AppModel
    let document: XCStringsDocument

    var body: some View {
        Group {
            if model.selectedEntryIDs.count > 1 {
                EmptyStateView(title: "Multiple selections", message: "Select a single entry to edit translations.")
            } else if let entry = model.selectedEntry {
                Form {
                    Section {
                        Text(entry.key)
                            .textSelection(.enabled)
                    } header: {
                        EntryDetailSectionHeaderView(title: "Key")
                    }

                    if let comment = entry.comment, !comment.isEmpty {
                        Section {
                            Text(comment)
                                .textSelection(.enabled)
                        } header: {
                            EntryDetailSectionHeaderView(title: "Comment")
                        }
                    }

                    Section {
                        ForEach(document.languages, id: \.self) { language in
                            TranslationRowView(
                                language: language,
                                isSource: language == document.sourceLanguage,
                                text: Binding(
                                    get: { model.translationValue(for: language) },
                                    set: { model.setTranslationValue($0, for: language) }
                                )
                            )
                        }
                    } header: {
                        EntryDetailSectionHeaderView(title: "Translations")
                    }
                }
                .formStyle(.grouped)
            } else {
                EmptyStateView(title: "Select a string", message: "Choose an entry in the list to review translations.")
            }
        }
    }
}
