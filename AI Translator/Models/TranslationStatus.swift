import Foundation

enum TranslationStatus: String, CaseIterable, Identifiable {
    case fullyTranslated
    case partiallyTranslated
    case notTranslated
    case doNotTranslate

    var id: String { rawValue }

    var displayName: String {
        switch self {
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
