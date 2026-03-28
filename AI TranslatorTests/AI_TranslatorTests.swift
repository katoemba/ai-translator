import Foundation
import Testing
@testable import AI_Translator

struct AI_TranslatorTests {

    @Test func translationStatusReflectsStates() async throws {
        let entry = XCStringsEntry(
            id: "hello",
            comment: nil,
            shouldTranslate: true,
            localizations: [
                "en": XCStringsLocalization(languageCode: "en", stringUnit: XCStringsStringUnit(state: "translated", value: "Hello"), extras: [:]),
                "fr": XCStringsLocalization(languageCode: "fr", stringUnit: XCStringsStringUnit(state: "needs-translation", value: ""), extras: [:])
            ],
            extras: [:]
        )

        let status = entry.translationStatus(targetLanguages: ["en", "fr"], sourceLanguage: "en")
        #expect(status == .partiallyTranslated)
    }

    @Test func doNotTranslateOverridesStatus() async throws {
        let entry = XCStringsEntry(
            id: "skip",
            comment: nil,
            shouldTranslate: false,
            localizations: [:],
            extras: [:]
        )

        let status = entry.translationStatus(targetLanguages: ["en", "fr"], sourceLanguage: "en")
        #expect(status == .doNotTranslate)
    }

    @Test func ensureLanguageAddsLocalization() async throws {
        let document = XCStringsDocument(
            fileURL: URL(fileURLWithPath: "/tmp/test.xcstrings"),
            sourceLanguage: "en",
            strings: [
                XCStringsEntry(
                    id: "hello",
                    comment: nil,
                    shouldTranslate: true,
                    localizations: ["en": XCStringsLocalization(languageCode: "en", stringUnit: XCStringsStringUnit(state: "translated", value: "Hello"), extras: [:])],
                    extras: [:]
                )
            ],
            languages: ["en"],
            documentExtras: [:]
        )

        await MainActor.run {
            document.ensureLanguageExists("fr")
        }
        let languageContains = await MainActor.run { document.languages.contains("fr") }
        #expect(languageContains)
        let entryLocalizationState = await MainActor.run {
            document.strings.first?.localizations["fr"]?.stringUnit?.state
        }
        #expect(entryLocalizationState == "needs-translation")
    }
}
