// MARK: - PaletteRole
//
// Algebraic type representing every semantic color role in the theme.
// Each role maps to one or more syntax elements in Xcode, Terminal, or an IDE.
//
// Roles are kept at the semantic level (what something *means*) rather than
// the tool level (what Xcode calls it). The mapping to tool-specific keys
// lives in the Theme layer.

public enum PaletteRole: String, CaseIterable, Sendable, Hashable, Identifiable {
    // MARK: Background / Selection
    case background         // editor canvas
    case selection          // selected text highlight
    case insertionPoint     // text cursor

    // MARK: Text
    case plainText          // default code text
    case comment            // // single-line comments
    case docComment         // /// documentation comments

    // MARK: Syntax — Declarations
    case keyword            // func, class, var, let, import, return…
    case typeIdentifier     // struct names, class names, protocol names
    case constantIdentifier // enum cases, static lets
    case variableIdentifier // local vars, parameters
    case functionIdentifier // function / method calls

    // MARK: Syntax — Literals
    case numberLiteral      // 42, 3.14, 0xFF
    case stringLiteral      // "hello"
    case attribute          // @propertyWrapper, @available
    case preprocessor       // #if, #warning, #selector

    public var id: String { rawValue }

    /// Human-readable display name for the editor UI.
    public var displayName: String {
        switch self {
        case .background:         return "Background"
        case .selection:          return "Selection"
        case .insertionPoint:     return "Cursor"
        case .plainText:          return "Plain Text"
        case .comment:            return "Comment"
        case .docComment:         return "Doc Comment"
        case .keyword:            return "Keyword"
        case .typeIdentifier:     return "Type Name"
        case .constantIdentifier: return "Constant"
        case .variableIdentifier: return "Variable"
        case .functionIdentifier: return "Function"
        case .numberLiteral:      return "Number"
        case .stringLiteral:      return "String"
        case .attribute:          return "Attribute"
        case .preprocessor:       return "Preprocessor"
        }
    }

    /// A representative snippet showing where this role appears in code.
    public var codeExample: String {
        switch self {
        case .background:         return "— editor canvas —"
        case .selection:          return "— selected text —"
        case .insertionPoint:     return "— text cursor —"
        case .plainText:          return "value"
        case .comment:            return "// Albers: color is never seen as it really is"
        case .docComment:         return "/// Generates a harmonious palette."
        case .keyword:            return "func"
        case .typeIdentifier:     return "ColorPalette"
        case .constantIdentifier: return "albersMidnight"
        case .variableIdentifier: return "baseHue"
        case .functionIdentifier: return "generatePalette()"
        case .numberLiteral:      return "0.72"
        case .stringLiteral:      return "\"Interaction of Color\""
        case .attribute:          return "@MainActor"
        case .preprocessor:       return "#if canImport(SwiftUI)"
        }
    }

    /// Whether this role represents a background (canvas / large area) color.
    public var isBackground: Bool {
        switch self {
        case .background, .selection: return true
        default: return false
        }
    }

    /// The minimum WCAG contrast ratio this role requires against `.background`.
    public var minimumContrastRatio: Double {
        switch self {
        case .background, .selection, .insertionPoint:
            return 1.0  // no foreground text requirement
        case .comment, .docComment:
            return 3.0  // AA large — comments are secondary
        default:
            return 4.5  // AA normal text
        }
    }
}
