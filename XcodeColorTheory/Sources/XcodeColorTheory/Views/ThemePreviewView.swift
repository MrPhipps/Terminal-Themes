import SwiftUI

// MARK: - ThemePreviewView
//
// The aesthetic validation surface. Renders a realistic Swift code snippet
// using the live palette colors. This is what you stare at for 10 hours —
// get this right first.
//
// Each line is hand-composed using AttributedString so every token
// gets exactly the right color from the palette.

public struct ThemePreviewView: View {
    public let palette: ColorPalette

    public init(palette: ColorPalette) {
        self.palette = palette
    }

    private var bg: Color { oklchToRGB(palette[.background]).swiftUIColor }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Editor chrome simulation
                editorHeader

                // Code area
                VStack(alignment: .leading, spacing: 0) {
                    codeLines
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
        }
        .background(bg)
        .navigationTitle("Preview")
        #if os(macOS)
        .toolbar { exportToolbarItems }
        #endif
    }

    // MARK: - Editor header (fake tab bar)

    private var editorHeader: some View {
        HStack(spacing: 0) {
            // Tab
            HStack(spacing: 6) {
                Image(systemName: "swift")
                    .font(.caption)
                Text("ColorPalette.swift")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(bg)
            .foregroundStyle(oklchToRGB(palette[.plainText]).swiftUIColor)

            Spacer()
        }
        .background(Color(white: 0.12))
    }

    // MARK: - Code lines

    @ViewBuilder
    private var codeLines: some View {
        let font = Font.system(size: 13, weight: .regular, design: .monospaced)

        // Line 1: import
        codeLine(lineNumber: 1, content: {
            token("import", role: .keyword, font: font)
            space()
            token("Foundation", role: .typeIdentifier, font: font)
        })

        blankLine(2)

        // Line 3: doc comment
        codeLine(lineNumber: 3, content: {
            token("/// Applies Josef Albers color theory to generate", role: .docComment, font: font)
        })
        codeLine(lineNumber: 4, content: {
            token("/// aesthetically harmonious Xcode color themes.", role: .docComment, font: font)
        })

        // Line 5: @MainActor
        codeLine(lineNumber: 5, content: {
            token("@MainActor", role: .attribute, font: font)
        })

        // Line 6: class
        codeLine(lineNumber: 6, content: {
            token("public", role: .keyword, font: font)
            space()
            token("final", role: .keyword, font: font)
            space()
            token("class", role: .keyword, font: font)
            space()
            token("ColorPalette", role: .typeIdentifier, font: font)
            token(": ", role: .plainText, font: font)
            token("ObservableObject", role: .typeIdentifier, font: font)
            token(" {", role: .plainText, font: font)
        })

        // Line 7: let name  (selected line — shows .selection bg + .insertionPoint cursor)
        codeLine(lineNumber: 7, isSelected: true, content: {
            tab()
            token("let", role: .keyword, font: font)
            space()
            token("name", role: .variableIdentifier, font: font)
            token(": ", role: .plainText, font: font)
            token("String", role: .typeIdentifier, font: font)
            token(" = ", role: .plainText, font: font)
            token("\"Albers Midnight\"", role: .stringLiteral, font: font)
        })

        // Line 8: let baseHue
        codeLine(lineNumber: 8, content: {
            tab()
            token("let", role: .keyword, font: font)
            space()
            token("baseHue", role: .variableIdentifier, font: font)
            token(": ", role: .plainText, font: font)
            token("Double", role: .typeIdentifier, font: font)
            token(" = ", role: .plainText, font: font)
            token("300", role: .numberLiteral, font: font)
            token(".0", role: .numberLiteral, font: font)
        })

        blankLine(9)

        // Line 10: // comment
        codeLine(lineNumber: 10, content: {
            tab()
            token("// Color is the most relative medium in art. — Josef Albers", role: .comment, font: font)
        })

        // Line 11: func
        codeLine(lineNumber: 11, content: {
            tab()
            token("func", role: .keyword, font: font)
            space()
            token("generatePalette", role: .functionIdentifier, font: font)
            token("(", role: .plainText, font: font)
            token("scheme", role: .variableIdentifier, font: font)
            token(": ", role: .plainText, font: font)
            token("HarmonyScheme", role: .typeIdentifier, font: font)
            token(") -> ", role: .plainText, font: font)
            token("ColorPalette", role: .typeIdentifier, font: font)
            token(" {", role: .plainText, font: font)
        })

        // Line 12: let hues
        codeLine(lineNumber: 12, content: {
            tab(); tab()
            token("let", role: .keyword, font: font)
            space()
            token("hues", role: .variableIdentifier, font: font)
            token(" = ", role: .plainText, font: font)
            token("accentHues", role: .functionIdentifier, font: font)
            token("(base: ", role: .plainText, font: font)
            token("baseHue", role: .variableIdentifier, font: font)
            token(", scheme: ", role: .plainText, font: font)
            token("scheme", role: .variableIdentifier, font: font)
            token(")", role: .plainText, font: font)
        })

        // Line 13: return
        codeLine(lineNumber: 13, content: {
            tab(); tab()
            token("return", role: .keyword, font: font)
            space()
            token("assignHuesToRoles", role: .functionIdentifier, font: font)
            token("(hues: ", role: .plainText, font: font)
            token("hues", role: .variableIdentifier, font: font)
            token(", background: palette[.background])", role: .plainText, font: font)
        })

        // Line 14: close func
        codeLine(lineNumber: 14, content: {
            tab()
            token("}", role: .plainText, font: font)
        })

        blankLine(15)

        // Line 16: #if
        codeLine(lineNumber: 16, content: {
            token("#if", role: .preprocessor, font: font)
            space()
            token("canImport", role: .functionIdentifier, font: font)
            token("(SwiftUI)", role: .plainText, font: font)
        })
        codeLine(lineNumber: 17, content: {
            tab()
            token("static let", role: .keyword, font: font)
            space()
            token("albersMidnight", role: .constantIdentifier, font: font)
            token(": ", role: .plainText, font: font)
            token("ColorPalette", role: .typeIdentifier, font: font)
            token(" = .init()", role: .plainText, font: font)
        })
        codeLine(lineNumber: 18, content: {
            token("#endif", role: .preprocessor, font: font)
        })

        // Line 19: close class
        codeLine(lineNumber: 19, content: {
            token("}", role: .plainText, font: font)
        })
    }

    // MARK: - Token helpers

    private func color(for role: PaletteRole) -> Color {
        oklchToRGB(palette[role]).swiftUIColor
    }

    private func token(_ text: String, role: PaletteRole, font: Font) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color(for: role))
    }

    private func space() -> some View { Text(" ").font(.system(size: 13, design: .monospaced)) }
    private func tab() -> some View { Text("    ").font(.system(size: 13, design: .monospaced)) }

    private func codeLine<Content: View>(
        lineNumber: Int,
        isSelected: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .center, spacing: 0) {
            // Gutter / line number
            Text("\(lineNumber)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(oklchToRGB(palette[.comment]).swiftUIColor.opacity(0.6))
                .frame(width: 32, alignment: .trailing)
                .padding(.trailing, 16)

            // Code tokens
            HStack(alignment: .center, spacing: 0) {
                content()
                if isSelected {
                    Text("|")
                        .font(.system(size: 13, weight: .light, design: .monospaced))
                        .foregroundStyle(oklchToRGB(palette[.insertionPoint]).swiftUIColor)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(height: 20)
        .background(
            isSelected
                ? oklchToRGB(palette[.selection]).swiftUIColor
                : Color.clear
        )
    }

    private func blankLine(_ number: Int) -> some View {
        codeLine(lineNumber: number) { EmptyView() }
    }

    // MARK: - Export toolbar

    @ToolbarContentBuilder
    private var exportToolbarItems: some ToolbarContent {
        ToolbarItem {
            ExportButton()
        }
    }
}

// MARK: - Export Button (inline toolbar item)

struct ExportButton: View {
    @State private var showExportSheet: Bool = false

    var body: some View {
        Button {
            showExportSheet = true
        } label: {
            Label("Export Theme", systemImage: "square.and.arrow.up")
        }
        .sheet(isPresented: $showExportSheet) {
            ExportView()
        }
    }
}
