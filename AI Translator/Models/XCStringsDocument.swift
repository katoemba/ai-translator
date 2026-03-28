import Foundation
import Observation

@MainActor
@Observable
final class XCStringsDocument {
    private(set) var fileURL: URL
    private(set) var sourceLanguage: String
    private(set) var strings: [XCStringsEntry]
    private(set) var languages: [String]

    private var documentExtras: [String: Any]

    init(fileURL: URL, sourceLanguage: String, strings: [XCStringsEntry], languages: [String], documentExtras: [String: Any]) {
        self.fileURL = fileURL
        self.sourceLanguage = sourceLanguage
        self.strings = strings
        self.languages = languages
        self.documentExtras = documentExtras
    }

    static func load(from fileURL: URL) async throws -> XCStringsDocument {
        let data = try Data(contentsOf: fileURL)
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let root = object as? [String: Any] else {
            throw XCStringsError.invalidFormat
        }

        let sourceLanguage = root["sourceLanguage"] as? String ?? "en"
        let stringsObject = root["strings"] as? [String: Any] ?? [:]
        var entries: [XCStringsEntry] = []
        var languageSet = Set<String>()

        for (key, value) in stringsObject {
            guard let entryDictionary = value as? [String: Any] else {
                continue
            }

            let comment = entryDictionary["comment"] as? String
            let shouldTranslate = entryDictionary["shouldTranslate"] as? Bool ?? true
            let localizationsObject = entryDictionary["localizations"] as? [String: Any] ?? [:]
            var localizations: [String: XCStringsLocalization] = [:]

            for (language, localizationValue) in localizationsObject {
                guard let localizationDictionary = localizationValue as? [String: Any] else {
                    continue
                }

                let stringUnitValue = localizationDictionary["stringUnit"] as? [String: Any]
                let stringUnitState = stringUnitValue?["state"] as? String
                let stringUnitText = stringUnitValue?["value"] as? String
                let stringUnit = (stringUnitState != nil || stringUnitText != nil) ? XCStringsStringUnit(state: stringUnitState ?? "", value: stringUnitText ?? "") : nil

                var localizationExtras = localizationDictionary
                localizationExtras.removeValue(forKey: "stringUnit")

                localizations[language] = XCStringsLocalization(languageCode: language, stringUnit: stringUnit, extras: localizationExtras)
                languageSet.insert(language)
            }

            var entryExtras = entryDictionary
            entryExtras.removeValue(forKey: "comment")
            entryExtras.removeValue(forKey: "shouldTranslate")
            entryExtras.removeValue(forKey: "localizations")

            entries.append(XCStringsEntry(id: key, comment: comment, shouldTranslate: shouldTranslate, localizations: localizations, extras: entryExtras))
        }

        var documentExtras = root
        documentExtras.removeValue(forKey: "sourceLanguage")
        documentExtras.removeValue(forKey: "strings")

        languageSet.insert(sourceLanguage)

        return XCStringsDocument(
            fileURL: fileURL,
            sourceLanguage: sourceLanguage,
            strings: entries.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending },
            languages: languageSet.sorted { $0.localizedStandardCompare($1) == .orderedAscending },
            documentExtras: documentExtras
        )
    }

    func updateTranslation(for entryID: String, language: String, value: String, state: String = "translated") {
        guard let index = strings.firstIndex(where: { $0.id == entryID }) else {
            return
        }

        var entry = strings[index]
        var localization = entry.localizations[language] ?? XCStringsLocalization(languageCode: language, stringUnit: nil, extras: [:])
        localization.stringUnit = XCStringsStringUnit(state: state, value: value)
        entry.localizations[language] = localization
        strings[index] = entry

        if !languages.contains(language) {
            languages.append(language)
            languages.sort { $0.localizedStandardCompare($1) == .orderedAscending }
        }
    }

    func ensureLanguageExists(_ language: String) {
        guard !languages.contains(language) else {
            return
        }

        languages.append(language)
        languages.sort { $0.localizedStandardCompare($1) == .orderedAscending }

        for index in strings.indices {
            var entry = strings[index]
            if entry.localizations[language] == nil {
                entry.localizations[language] = XCStringsLocalization(
                    languageCode: language,
                    stringUnit: XCStringsStringUnit(state: "needs-translation", value: ""),
                    extras: [:]
                )
                strings[index] = entry
            }
        }
    }

    func stringValue(for entryID: String, language: String) -> String {
        guard let entry = strings.first(where: { $0.id == entryID }) else {
            return ""
        }
        return entry.localizations[language]?.stringUnit?.value ?? ""
    }

    func setStringValue(_ value: String, for entryID: String, language: String) {
        guard let index = strings.firstIndex(where: { $0.id == entryID }) else {
            return
        }

        var entry = strings[index]
        var localization = entry.localizations[language] ?? XCStringsLocalization(languageCode: language, stringUnit: nil, extras: [:])
        let state = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "needs-translation" : "translated"
        localization.stringUnit = XCStringsStringUnit(state: state, value: value)
        entry.localizations[language] = localization
        strings[index] = entry

        if !languages.contains(language) {
            languages.append(language)
            languages.sort { $0.localizedStandardCompare($1) == .orderedAscending }
        }
    }

    func save() async throws {
        var root = documentExtras
        root["sourceLanguage"] = sourceLanguage

        var stringsDictionary: [String: Any] = [:]
        let sortedEntries = strings.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }

        for entry in sortedEntries {
            var entryDictionary = entry.extras
            if let comment = entry.comment {
                entryDictionary["comment"] = comment
            }
            if entry.shouldTranslate == false {
                entryDictionary["shouldTranslate"] = entry.shouldTranslate
            }
            else {
                var localizationsDictionary: [String: Any] = [:]
                let sortedLocalizations = entry.localizations.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
                
                for language in sortedLocalizations {
                    guard let localization = entry.localizations[language] else {
                        continue
                    }
                    var localizationDictionary = localization.extras
                    if let stringUnit = localization.stringUnit {
                        localizationDictionary["stringUnit"] = [
                            "state": stringUnit.state,
                            "value": stringUnit.value
                        ]
                    }
                    localizationsDictionary[language] = localizationDictionary
                }
                
                entryDictionary["localizations"] = localizationsDictionary
            }
            stringsDictionary[entry.key] = entryDictionary
        }

        root["strings"] = stringsDictionary
        let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: fileURL, options: [.atomic])
    }

    func save(to fileURL: URL) async throws {
        self.fileURL = fileURL
        try await save()
    }
}


enum XCStringsError: LocalizedError {
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The selected file is not a valid .xcstrings file."
        }
    }
}
