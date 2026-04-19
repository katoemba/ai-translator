import Foundation
import Observation
#if os(macOS)
import AppKit
#endif

@MainActor
@Observable
final class AppModel {
    var document: XCStringsDocument?
    var selectedEntryIDs: Set<String> = []
    var translationFilter: TranslationFilter = .all
    var filterText: String = ""
    var isTranslating = false
    var progressCompleted = 0
    var progressTotal = 0
    var errorMessage: String?

    private let openAIClient = OpenAIClient()

    var filteredEntries: [XCStringsEntry] {
        guard let document else {
            return []
        }

        let entries = document.strings.filter { entry in
            switch translationFilter {
            case .all:
                return true
            case .fullyTranslated:
                return entry.translationStatus(targetLanguages: document.languages, sourceLanguage: document.sourceLanguage) == .fullyTranslated
            case .partiallyTranslated:
                return entry.translationStatus(targetLanguages: document.languages, sourceLanguage: document.sourceLanguage) == .partiallyTranslated
            case .notTranslated:
                return entry.translationStatus(targetLanguages: document.languages, sourceLanguage: document.sourceLanguage) == .notTranslated
            case .doNotTranslate:
                return entry.translationStatus(targetLanguages: document.languages, sourceLanguage: document.sourceLanguage) == .doNotTranslate
            }
        }

        let query = filterText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return entries
        }

        return entries.filter { entry in
            if entry.id.localizedStandardContains(query) {
                return true
            }

            if let comment = entry.comment, comment.localizedStandardContains(query) {
                return true
            }

            let sourceText = entry.localizations[document.sourceLanguage]?.stringUnit?.value ?? ""
            return sourceText.localizedStandardContains(query)
        }
    }

    var selectedEntry: XCStringsEntry? {
        guard selectedEntryIDs.count == 1, let selectedEntryID = selectedEntryIDs.first else {
            return nil
        }
        return document?.strings.first(where: { $0.id == selectedEntryID })
    }

    func loadDocument(from fileURL: URL) async -> Bool {
        do {
            document = try await XCStringsDocument.load(from: fileURL)
            if let firstID = document?.strings.first?.id {
                selectedEntryIDs = [firstID]
            } else {
                selectedEntryIDs = []
            }
            #if os(macOS)
            NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
            #endif
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func saveDocumentAs(to fileURL: URL) async -> Bool {
        guard let document else {
            return false
        }

        do {
            try await document.save(to: fileURL)
            #if os(macOS)
            NSDocumentController.shared.noteNewRecentDocumentURL(fileURL)
            #endif
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func saveDocument() async {
        guard let document else {
            return
        }

        do {
            try await document.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addLanguage(_ language: String) {
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        document?.ensureLanguageExists(trimmed)
    }

    func translationValue(for language: String) -> String {
        guard selectedEntryIDs.count == 1, let entryID = selectedEntryIDs.first else {
            return ""
        }
        return document?.stringValue(for: entryID, language: language) ?? ""
    }

    func setTranslationValue(_ value: String, for language: String) {
        guard selectedEntryIDs.count == 1, let entryID = selectedEntryIDs.first else {
            return
        }
        document?.setStringValue(value, for: entryID, language: language)
    }

    func translateSelected(token: String, context: String) async {
        guard let document, !selectedEntryIDs.isEmpty else {
            return
        }

        let entries = document.strings.filter { selectedEntryIDs.contains($0.id) }
        await translate(entries: entries, token: token, context: context, force: true)
    }

    func translateAll(token: String, context: String) async {
        guard let document else {
            return
        }

        let entries = document.strings.filter { entry in
            let status = entry.translationStatus(targetLanguages: document.languages, sourceLanguage: document.sourceLanguage)
            return status == .notTranslated || status == .partiallyTranslated
        }
        await translate(entries: entries, token: token, context: context)
    }

    private func translate(entries: [XCStringsEntry], token: String, context: String, force: Bool = false) async {
        guard let document else {
            return
        }

        let targets = document.languages.filter { $0 != document.sourceLanguage }
        guard !targets.isEmpty else {
            return
        }

        isTranslating = true
        progressCompleted = 0
        progressTotal = entries.count

        defer {
            isTranslating = false
        }

        for entry in entries {
            if Task.isCancelled {
                break
            }

            guard entry.shouldTranslate else {
                progressCompleted += 1
                continue
            }

            let sourceText = entry.localizations[document.sourceLanguage]?.stringUnit?.value ?? ""
            let resolvedSourceText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? entry.id : sourceText
            if resolvedSourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                progressCompleted += 1
                continue
            }

            let missingTargets = force ? targets : targets.filter { language in
                guard let stringUnit = entry.localizations[language]?.stringUnit else {
                    return true
                }
                return stringUnit.state != "translated" || stringUnit.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }

            if missingTargets.isEmpty {
                progressCompleted += 1
                continue
            }

            do {
                let translations = try await openAIClient.translate(
                    text: resolvedSourceText,
                    sourceLanguage: document.sourceLanguage,
                    targetLanguages: missingTargets,
                    token: token,
                    context: context
                )

                for (language, translation) in translations {
                    document.updateTranslation(for: entry.id, language: language, value: translation, state: "translated")
                }
            } catch {
                errorMessage = error.localizedDescription
            }

            progressCompleted += 1
        }
    }
}
