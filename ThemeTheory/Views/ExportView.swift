import ThemeTheory
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - ExportView
//
// Sheet that handles exporting the current palette as a .xccolortheme file.
// Three export paths:
//   1. Direct install → Xcode's FontAndColorThemes directory
//   2. Downloads → user's Downloads folder
//   3. Copy XML → clipboard (no file system needed; works on iOS)

struct ExportView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    // Font selection uses a preset label as the Picker tag to avoid needing FontHierarchy: Hashable
    @State private var selectedPresetLabel: String = FontHierarchy.allPresets[0].label
    @State private var showCopiedFeedback: Bool = false

    private var selectedHierarchy: FontHierarchy {
        FontHierarchy.allPresets.first(where: { $0.label == selectedPresetLabel })?.hierarchy ?? .default
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Theme") {
                    LabeledContent("Name", value: env.selectedPalette.name)
                    LabeledContent("Roles", value: "\(env.selectedPalette.colors.count) color roles")
                }

                Section("Font") {
                    Picker("Preset", selection: $selectedPresetLabel) {
                        ForEach(FontHierarchy.allPresets, id: \.label) { label, _ in
                            Text(label).tag(label)
                        }
                    }

                    ForEach(FontCategory.allCases, id: \.self) { category in
                        LabeledContent(category.displayName) {
                            Text(selectedHierarchy[category].familyName)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Export") {
                    #if os(macOS)
                    Button {
                        Task {
                            await env.exportToXcodeThemes(fontHierarchy: selectedHierarchy)
                            if env.exportState.errorMessage == nil { dismiss() }
                        }
                    } label: {
                        Label(
                            env.exportState.isExporting ? "Exporting…" : "Install into Xcode",
                            systemImage: "xcode"
                        )
                    }
                    .disabled(env.exportState.isExporting)
                    #endif

                    Button {
                        Task {
                            await env.exportToDownloads(fontHierarchy: selectedHierarchy)
                            if env.exportState.errorMessage == nil { dismiss() }
                        }
                    } label: {
                        Label(
                            env.exportState.isExporting ? "Saving…" : "Save to Downloads",
                            systemImage: "folder"
                        )
                    }
                    .disabled(env.exportState.isExporting)

                    Button {
                        Task {
                            let xml: String = env.xmlString(fontHierarchy: selectedHierarchy)
                            #if canImport(AppKit)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(xml, forType: .string)
                            #elseif canImport(UIKit)
                            UIPasteboard.general.string = xml
                            #endif
                            showCopiedFeedback = true
                            try? await Task.sleep(for: .seconds(2))
                            showCopiedFeedback = false
                        }
                    } label: {
                        Label(
                            showCopiedFeedback ? "Copied!" : "Copy XML to Clipboard",
                            systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc"
                        )
                    }
                    .foregroundStyle(showCopiedFeedback ? .green : .accentColor)
                }

                // Export state feedback
                switch env.exportState {
                case .failure(let message):
                    Section {
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    }
                case .success(let url):
                    Section("Installed") {
                        Label("Saved to \(url.lastPathComponent)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        #if os(macOS)
                        if url.path.contains("Xcode") {
                            Text("Restart Xcode or open Preferences → Themes to activate.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        #endif
                    }
                case .idle, .exporting:
                    EmptyView()
                }

                Section("Installation Guide") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Manual install:")
                            .font(.caption.weight(.semibold))
                        Text("Copy the .xccolortheme file to:\n~/Library/Developer/Xcode/UserData/FontAndColorThemes/")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("Then restart Xcode and select the theme in Settings → Themes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Export Theme")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 400)
        #endif
    }
}
