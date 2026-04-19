import SwiftUI

struct EntryListView: View {
    let entries: [XCStringsEntry]
    let document: XCStringsDocument?
    @Binding var selection: Set<String>

    var body: some View {
        List(entries, selection: $selection) { entry in
            HStack(alignment: .center) {
                if let document {
                    entry.translationStatus(targetLanguages: document.languages, sourceLanguage: document.sourceLanguage).displayImage
                }
                
                Text(entry.key)
            }
        }
    }
}
