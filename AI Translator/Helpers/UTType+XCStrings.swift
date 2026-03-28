import UniformTypeIdentifiers

extension UTType {
    static var xcstrings: UTType {
        UTType(filenameExtension: "xcstrings") ?? .json
    }
}
