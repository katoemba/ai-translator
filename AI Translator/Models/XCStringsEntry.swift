import Foundation

struct XCStringsEntry: Identifiable {
    let id: String
    var comment: String?
    var shouldTranslate: Bool
    var localizations: [String: XCStringsLocalization]
    var extras: [String: Any]

    var key: String { id }

    func translationStatus(targetLanguages: [String], sourceLanguage: String) -> TranslationStatus {
        guard shouldTranslate else {
            return .doNotTranslate
        }

        let languages = targetLanguages.filter { $0 != sourceLanguage }
        guard !languages.isEmpty else {
            return .fullyTranslated
        }

        let translatedCount = languages.filter { language in
            guard let stringUnit = localizations[language]?.stringUnit else {
                return false
            }
            return stringUnit.state == "translated" && !stringUnit.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count

        if translatedCount == 0 {
            return .notTranslated
        }

        if translatedCount == languages.count {
            return .fullyTranslated
        }

        return .partiallyTranslated
    }
}
