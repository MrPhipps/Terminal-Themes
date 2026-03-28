import Foundation

// MARK: - ThemeExporter (actor — imperative shell)
//
// All file I/O is isolated to this actor. The domain (pure functions) never touches
// the filesystem. The actor calls serialize() from the domain and writes the result.

/// Errors that can occur during theme export.
public enum ExportError: Error, Sendable {
    case serializationFailed(String)
    case writePermissionDenied(URL)
    case directoryNotFound(URL)
    case fileAlreadyExists(URL)
}

/// Manages exporting themes to `.xccolortheme` files.
///
/// Usage:
/// ```swift
/// let exporter = ThemeExporter()
/// let url = try await exporter.exportToXcodeThemes(palette: .albersMidnight)
/// ```
public actor ThemeExporter {
    public init() {}

    // MARK: - Export to custom URL

    /// Exports a palette as a `.xccolortheme` file to the given URL.
    ///
    /// - Parameters:
    ///   - palette: The color palette to export.
    ///   - url: The destination file URL (should have `.xccolortheme` extension).
    ///   - overwrite: If false and the file exists, throws `fileAlreadyExists`.
    ///   - font: The font to embed in the theme. Defaults to JetBrains Mono 13pt.
    public func export(
        palette: ColorPalette,
        to url: URL,
        overwrite: Bool = true,
        font: ThemeFont = .default
    ) async throws {
        let theme: XcodeColorTheme = xcodeTheme(from: palette, font: font)
        let xml: String = serialize(theme)

        guard let data = xml.data(using: .utf8) else {
            throw ExportError.serializationFailed("Failed to encode theme XML as UTF-8")
        }

        let fm: FileManager = FileManager.default

        // Ensure parent directory exists
        let directory: URL = url.deletingLastPathComponent()
        guard fm.fileExists(atPath: directory.path) else {
            throw ExportError.directoryNotFound(directory)
        }

        // Check for existing file
        if !overwrite && fm.fileExists(atPath: url.path) {
            throw ExportError.fileAlreadyExists(url)
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch CocoaError.fileWriteNoPermission {
            throw ExportError.writePermissionDenied(url)
        }
    }

    // MARK: - Export to Xcode's theme directory

    /// Exports directly to Xcode's user theme folder.
    ///
    /// The file will appear in Xcode → Settings → Themes immediately (restart not required
    /// in Xcode 15+). If the Xcode theme directory doesn't exist, it is created.
    ///
    /// - Returns: The URL of the written file.
    @discardableResult
    public func exportToXcodeThemes(
        palette: ColorPalette,
        overwrite: Bool = true,
        font: ThemeFont = .default
    ) async throws -> URL {
        let themesDir: URL = xcodeThemesDirectory()
        try FileManager.default.createDirectory(at: themesDir, withIntermediateDirectories: true)

        let fileName: String = safeFileName(for: palette.name) + ".xccolortheme"
        let url: URL = themesDir.appendingPathComponent(fileName)
        try await export(palette: palette, to: url, overwrite: overwrite, font: font)
        return url
    }

    // MARK: - Export to Downloads

    /// Exports the theme to `~/Downloads` — useful when Xcode isn't installed
    /// or for sharing themes.
    ///
    /// - Returns: The URL of the written file.
    @discardableResult
    public func exportToDownloads(
        palette: ColorPalette,
        overwrite: Bool = true,
        font: ThemeFont = .default
    ) async throws -> URL {
        let downloads: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let fileName: String = safeFileName(for: palette.name) + ".xccolortheme"
        let url: URL = downloads.appendingPathComponent(fileName)
        try await export(palette: palette, to: url, overwrite: overwrite, font: font)
        return url
    }

    // MARK: - Private

    private func xcodeThemesDirectory() -> URL {
        return FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/UserData/FontAndColorThemes")
    }

    /// Sanitizes a palette name into a safe filename component.
    ///
    /// Strips path separators (`/`, `\`), dot-segments (`..`), null bytes,
    /// and any control characters. Collapses runs of whitespace to a single space.
    /// Falls back to "Untitled" if the result is empty.
    private func safeFileName(for paletteName: String) -> String {
        // Allowed: alphanumerics, spaces, hyphens, underscores, parentheses, periods (single)
        let allowed: CharacterSet = CharacterSet.alphanumerics
            .union(.init(charactersIn: " -_()."))

        let sanitized: String = paletteName
            .unicodeScalars
            .filter { allowed.contains($0) }
            .reduce(into: "") { result, scalar in
                // Collapse consecutive spaces
                if scalar == " " && result.last == " " { return }
                result.append(Character(scalar))
            }
            .trimmingCharacters(in: .whitespaces)

        return sanitized.isEmpty ? "Untitled" : sanitized
    }
}
