import Foundation

enum TranslationFilter: String, CaseIterable, Identifiable {
    case all
    case fullyTranslated
    case partiallyTranslated
    case notTranslated
    case doNotTranslate

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .all:
            return "All"
        case .fullyTranslated:
            return "Fully translated"
        case .partiallyTranslated:
            return "Partially translated"
        case .notTranslated:
            return "Not translated"
        case .doNotTranslate:
            return "Do not translate"
        }
    }
}
