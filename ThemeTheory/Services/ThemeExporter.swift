import ThemeTheory
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
    public func export(
        palette: ColorPalette,
        to url: URL,
        overwrite: Bool = true,
        fontHierarchy: FontHierarchy = .default
    ) async throws {
        let theme: XcodeColorTheme = xcodeTheme(from: palette, fontHierarchy: fontHierarchy)
        let xml: String = serialize(theme)

        guard let data = xml.data(using: .utf8) else {
            throw ExportError.serializationFailed("Failed to encode theme XML as UTF-8")
        }

        let fm: FileManager = FileManager.default

        let directory: URL = url.deletingLastPathComponent()
        guard fm.fileExists(atPath: directory.path) else {
            throw ExportError.directoryNotFound(directory)
        }

        if !overwrite && fm.fileExists(atPath: url.path) {
            throw ExportError.fileAlreadyExists(url)
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch CocoaError.fileWriteNoPermission {
            throw ExportError.writePermissionDenied(url)
        }
    }

    // MARK: - Export to Xcode's theme directory (macOS only)

    #if os(macOS)
    /// Exports directly to Xcode's user theme folder.
    @discardableResult
    public func exportToXcodeThemes(
        palette: ColorPalette,
        overwrite: Bool = true,
        fontHierarchy: FontHierarchy = .default
    ) async throws -> URL {
        let themesDir: URL = xcodeThemesDirectory()
        try FileManager.default.createDirectory(at: themesDir, withIntermediateDirectories: true)

        let fileName: String = safeFileName(for: palette.name) + ".xccolortheme"
        let url: URL = themesDir.appendingPathComponent(fileName)
        try await export(palette: palette, to: url, overwrite: overwrite, fontHierarchy: fontHierarchy)
        return url
    }
    #endif

    // MARK: - Export to Downloads

    /// Exports the theme to `~/Downloads`.
    @discardableResult
    public func exportToDownloads(
        palette: ColorPalette,
        overwrite: Bool = true,
        fontHierarchy: FontHierarchy = .default
    ) async throws -> URL {
        guard let downloads: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            throw ExportError.serializationFailed("Downloads directory unavailable on this device")
        }
        let fileName: String = safeFileName(for: palette.name) + ".xccolortheme"
        let url: URL = downloads.appendingPathComponent(fileName)
        try await export(palette: palette, to: url, overwrite: overwrite, fontHierarchy: fontHierarchy)
        return url
    }

    // MARK: - Private

    #if os(macOS)
    private func xcodeThemesDirectory() -> URL {
        return FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/Xcode/UserData/FontAndColorThemes")
    }
    #endif

    private func safeFileName(for paletteName: String) -> String {
        let allowed: CharacterSet = CharacterSet.alphanumerics
            .union(.init(charactersIn: " -_()."))

        let sanitized: String = paletteName
            .unicodeScalars
            .filter { allowed.contains($0) }
            .reduce(into: "") { result, scalar in
                if scalar == " " && result.last == " " { return }
                result.append(Character(scalar))
            }
            .trimmingCharacters(in: .whitespaces)

        return sanitized.isEmpty ? "Untitled" : sanitized
    }
}
