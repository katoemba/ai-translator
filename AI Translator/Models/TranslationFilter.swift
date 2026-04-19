import Foundation
import SwiftUI

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
    
    var displayImage: some View {
        switch self {
        case .doNotTranslate:
            return Image(systemName: "circle.dashed")
                .foregroundColor(.gray)
        case .fullyTranslated:
            return Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .partiallyTranslated:
            return Image(systemName: "pencil.circle")
                .foregroundColor(.yellow)
        case .notTranslated:
            return Image(systemName: "circle.slash")
                .foregroundColor(.red)
        case .all:
            return Image(systemName: "star")
                .foregroundColor(.red)
        }
    }
}
