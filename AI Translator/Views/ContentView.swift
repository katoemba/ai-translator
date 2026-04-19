import SwiftUI
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

struct ContentView: View {
    @State private var model = AppModel()
    @State private var isShowingImporter = false
    @State private var isShowingAddLanguage = false
    @State private var activeFileURL: URL?
    @State private var didAttemptInitialOpen = false
    @AppStorage("openaiToken") private var openAIToken = ""
    @AppStorage("openaiContext") private var openAIContext = ""
    @AppStorage("lastOpenedXCStringsPath") private var lastOpenedXCStringsPath = ""

    var body: some View {
        NavigationSplitView {
            if let document = model.document {
                VStack(alignment: .leading) {
                    Text("Filter")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    Picker("Filter", selection: $model.translationFilter) {
                        ForEach(TranslationFilter.allCases) { filter in
                            switch filter {
                            case .all:
                                Text(filter.displayName).tag(filter)
                            default:
                                filter.displayImage.tag(filter)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                    .labelsHidden()
                    .padding(.horizontal)

                    EntryListView(entries: model.filteredEntries, document: document, selection: $model.selectedEntryIDs)
                        .searchable(text: $model.filterText, placement: .sidebar, prompt: "Filter entries")
                }
            } else {
                EmptyStateView(title: "Open a .xcstrings file", message: "Choose a file to start translating.")
            }
        } detail: {
            if let document = model.document {
                EntryDetailView(model: model, document: document)
            } else {
                EmptyStateView(title: "No file selected", message: "Open a .xcstrings file to view translations.")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Open", systemImage: "folder") {
                    isShowingImporter = true
                }
                .help("Open a .xcstrings file")
            }

            ToolbarItem {
                Button("Add Language", systemImage: "plus") {
                    isShowingAddLanguage = true
                }
                .disabled(model.document == nil)
                .help("Add a target language")
            }

            ToolbarItemGroup {
                Button("Translate All", systemImage: "sparkles") {
                    Task {
                        await model.translateAll(token: openAIToken, context: openAIContext)
                    }
                }
                .disabled(openAIToken.isEmpty || model.document == nil || model.isTranslating)
                .help("Translate all missing or partial entries")

                Button("Translate Selected", systemImage: "text.badge.plus") {
                    Task {
                        await model.translateSelected(token: openAIToken, context: openAIContext)
                    }
                }
                .disabled(openAIToken.isEmpty || model.selectedEntryIDs.isEmpty || model.isTranslating)
                .help("Translate the selected entries")
            }

            ToolbarItem {
                Button("Save", systemImage: "square.and.arrow.down") {
                    Task {
                        await model.saveDocument()
                    }
                }
                .disabled(model.document == nil || model.isTranslating)
                .help("Save changes to the .xcstrings file")
            }

            ToolbarItem {
                if model.isTranslating {
                    ProgressView(value: Double(model.progressCompleted), total: Double(max(model.progressTotal, 1)))
                        .help("Translation progress")
                }
            }
        }
        .focusedSceneValue(\.openDocument, { isShowingImporter = true })
        .focusedSceneValue(\.openRecentDocument, { url in openDocument(url: url) })
        .focusedSceneValue(\.recentDocumentURLs, recentDocumentURLs())
        .focusedSceneValue(\.saveDocument, model.document == nil ? nil : { Task { await model.saveDocument() } })
        .focusedSceneValue(\.saveDocumentAs, model.document == nil ? nil : { saveDocumentAs() })
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.xcstrings]
        ) { result in
            switch result {
            case .success(let url):
                openDocument(url: url)
            case .failure(let error):
                model.errorMessage = error.localizedDescription
            }
        }
        .task {
            guard !didAttemptInitialOpen else {
                return
            }
            didAttemptInitialOpen = true
            await attemptInitialOpen()
        }
        .sheet(isPresented: $isShowingAddLanguage) {
            AddLanguageView { language in
                model.addLanguage(language)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    model.errorMessage = nil
                }
            }
        )) {
            Button("OK") {}
        } message: {
            Text(model.errorMessage ?? "")
        }
        .onDisappear {
            activeFileURL?.stopAccessingSecurityScopedResource()
        }
    }

    private func openDocument(url: URL) {
        activeFileURL?.stopAccessingSecurityScopedResource()
        activeFileURL = url
        if url.startAccessingSecurityScopedResource() {
            Task {
                let didLoad = await model.loadDocument(from: url)
                if didLoad {
                    lastOpenedXCStringsPath = url.path
                }
            }
        } else {
            model.errorMessage = "Unable to access the selected file."
        }
    }

    private func attemptInitialOpen() async {
        guard !lastOpenedXCStringsPath.isEmpty else {
            isShowingImporter = true
            return
        }

        let url = URL(fileURLWithPath: lastOpenedXCStringsPath)
        if FileManager.default.fileExists(atPath: url.path) {
            openDocument(url: url)
        } else {
            lastOpenedXCStringsPath = ""
            isShowingImporter = true
        }
    }

    private func recentDocumentURLs() -> [URL] {
        #if os(macOS)
        return NSDocumentController.shared.recentDocumentURLs
        #else
        return []
        #endif
    }

    private func saveDocumentAs() {
        #if os(macOS)
        Task {
            guard let url = await presentSavePanel() else {
                return
            }
            if await model.saveDocumentAs(to: url) {
                lastOpenedXCStringsPath = url.path
            }
        }
        #endif
    }

    #if os(macOS)
    private func presentSavePanel() async -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.xcstrings]
        panel.nameFieldStringValue = model.document?.fileURL.lastPathComponent ?? "Localizable.xcstrings"

        return await withCheckedContinuation { continuation in
            panel.begin { response in
                continuation.resume(returning: response == .OK ? panel.url : nil)
            }
        }
    }
    #endif
}

