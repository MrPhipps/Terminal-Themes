// MARK: - SyntaxRole
//
// Algebraic type mapping each Xcode DVT syntax color key to a PaletteRole.
// This is the bridge between the semantic palette and the tool-specific format.
//
// Xcode reads these keys from DVTSourceTextSyntaxColors in the .xccolortheme plist.
// Font keys live in DVTSourceTextSyntaxFonts.
//
// SCALABILITY:
// Xcode's DVT syntax key set is fixed by Apple — new keys are rare and additive.
// This enum is therefore intentionally exhaustive: a `CaseIterable` exhaustive enum
// catches missing mappings at compile time rather than at runtime.
//
// For other IDEs, the pattern scales horizontally rather than vertically:
// each target format gets its own role enum (e.g. `VSCodeTokenRole`,
// `JetBrainsTokenRole`) that maps to the *same* `PaletteRole` semantic layer.
// The palette and Albers logic are untouched; only a new serializer is added.
// See `ThemeSerializer.swift` for how the mapping is consumed.

/// All Xcode syntax color keys recognized in a `.xccolortheme` file.
public enum SyntaxRole: String, CaseIterable, Sendable {
    case plain                  = "xcode.syntax.plain"
    case comment                = "xcode.syntax.comment"
    case commentDoc             = "xcode.syntax.comment.doc"
    case commentDocKeyword      = "xcode.syntax.comment.doc.keyword"
    case keyword                = "xcode.syntax.keyword"
    case identifierType         = "xcode.syntax.identifier.type"
    case identifierTypeSystem   = "xcode.syntax.identifier.type.system"
    case identifierConstant     = "xcode.syntax.identifier.constant"
    case identifierVariable     = "xcode.syntax.identifier.variable"
    case identifierFunction     = "xcode.syntax.identifier.function"
    case identifierFunctionSystem = "xcode.syntax.identifier.function.system"
    case number                 = "xcode.syntax.number"
    case string                 = "xcode.syntax.string"
    case character              = "xcode.syntax.character"
    case url                    = "xcode.syntax.url"
    case attribute              = "xcode.syntax.attribute"
    case preprocessor           = "xcode.syntax.preprocessor"
    case otherDeclarationType   = "xcode.syntax.other.declaration.type"
    case otherName              = "xcode.syntax.other.name"
    case otherOperator          = "xcode.syntax.other.operator"

    /// Maps this Xcode syntax role to the corresponding semantic PaletteRole.
    public var paletteRole: PaletteRole {
        switch self {
        case .plain:                    return .plainText
        case .comment:                  return .comment
        case .commentDoc:               return .docComment
        case .commentDocKeyword:        return .docComment
        case .keyword:                  return .keyword
        case .identifierType:           return .typeIdentifier
        case .identifierTypeSystem:     return .typeIdentifier
        case .identifierConstant:       return .constantIdentifier
        case .identifierVariable:       return .variableIdentifier
        case .identifierFunction:       return .functionIdentifier
        case .identifierFunctionSystem: return .functionIdentifier
        case .number:                   return .numberLiteral
        case .string:                   return .stringLiteral
        case .character:                return .stringLiteral
        case .url:                      return .plainText
        case .attribute:                return .attribute
        case .preprocessor:             return .preprocessor
        case .otherDeclarationType:     return .typeIdentifier
        case .otherName:                return .plainText
        case .otherOperator:            return .keyword
        }
    }
}
