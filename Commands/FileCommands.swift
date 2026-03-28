import SwiftUI

struct FileCommands: Commands {
    @FocusedSceneValue(\.openDocument) private var openDocument
    @FocusedSceneValue(\.openRecentDocument) private var openRecentDocument
    @FocusedSceneValue(\.recentDocumentURLs) private var recentDocumentURLs
    @FocusedSceneValue(\.saveDocument) private var saveDocument
    @FocusedSceneValue(\.saveDocumentAs) private var saveDocumentAs

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open...") {
                openDocument?()
            }
            .keyboardShortcut("o", modifiers: [.command])
            .disabled(openDocument == nil)

            Menu("Open Recent") {
                if let recentDocumentURLs, !recentDocumentURLs.isEmpty {
                    ForEach(recentDocumentURLs, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            openRecentDocument?(url)
                        }
                    }
                } else {
                    Button("No Recent Files") {}
                        .disabled(true)
                }
            }
            .disabled(openRecentDocument == nil)
        }

        CommandGroup(after: .saveItem) {
            Button("Save") {
                saveDocument?()
            }
            .keyboardShortcut("s", modifiers: [.command])
            .disabled(saveDocument == nil)

            Button("Save As...") {
                saveDocumentAs?()
            }
            .keyboardShortcut("S", modifiers: [.command, .shift])
            .disabled(saveDocumentAs == nil)
        }
    }
}

private struct OpenDocumentKey: FocusedSceneValueKey {
    typealias Value = () -> Void
}

private struct OpenRecentDocumentKey: FocusedSceneValueKey {
    typealias Value = (URL) -> Void
}

private struct RecentDocumentURLsKey: FocusedSceneValueKey {
    typealias Value = [URL]
}

private struct SaveDocumentKey: FocusedSceneValueKey {
    typealias Value = () -> Void
}

private struct SaveDocumentAsKey: FocusedSceneValueKey {
    typealias Value = () -> Void
}

extension FocusedSceneValues {
    var openDocument: (() -> Void)? {
        get { self[OpenDocumentKey.self] }
        set { self[OpenDocumentKey.self] = newValue }
    }

    var openRecentDocument: ((URL) -> Void)? {
        get { self[OpenRecentDocumentKey.self] }
        set { self[OpenRecentDocumentKey.self] = newValue }
    }

    var recentDocumentURLs: [URL]? {
        get { self[RecentDocumentURLsKey.self] }
        set { self[RecentDocumentURLsKey.self] = newValue }
    }

    var saveDocument: (() -> Void)? {
        get { self[SaveDocumentKey.self] }
        set { self[SaveDocumentKey.self] = newValue }
    }

    var saveDocumentAs: (() -> Void)? {
        get { self[SaveDocumentAsKey.self] }
        set { self[SaveDocumentAsKey.self] = newValue }
    }
}
