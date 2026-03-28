import SwiftUI

struct EntryListView: View {
    let entries: [XCStringsEntry]
    let document: XCStringsDocument?
    @Binding var selection: Set<String>

    var body: some View {
        List(entries, selection: $selection) { entry in
            HStack(alignment: .center) {
                if let document {
                    switch entry.translationStatus(targetLanguages: document.languages, sourceLanguage: document.sourceLanguage) {
                    case .doNotTranslate: Image(systemName: "circle.dashed")
                            .foregroundColor(.gray)
                    case .fullyTranslated: Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .partiallyTranslated: Image(systemName: "pencil.circle")
                            .foregroundColor(.yellow)
                    case .notTranslated: Image(systemName: "circle.slash")
                            .foregroundColor(.red)
                    }
                }
                
                Text(entry.key)
            }
        }
    }
}
