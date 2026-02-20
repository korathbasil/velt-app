import Foundation

// ==========================================
// PRIMITIVE WIDGETS & THEME
// ==========================================

/// Material 3 elevation levels for depth and hierarchy
public enum Elevation {
    case level0  // No elevation
    case level1  // 1dp - subtle shadow
    case level2  // 3dp - raised elements
    case level3  // 6dp - floating elements
    case level4  // 8dp - FABs and menus
    case level5  // 12dp - dialogs

    var shadowAlpha: Float {
        switch self {
        case .level0: return 0.0
        case .level1: return 0.08
        case .level2: return 0.12
        case .level3: return 0.16
        case .level4: return 0.20
        case .level5: return 0.25
        }
    }

    var shadowBlur: Float {
        switch self {
        case .level0: return 0
        case .level1: return 4
        case .level2: return 6
        case .level3: return 10
        case .level4: return 14
        case .level5: return 18
        }
    }

    var shadowOffset: Float {
        switch self {
        case .level0: return 0
        case .level1: return 2
        case .level2: return 3
        case .level3: return 5
        case .level4: return 7
        case .level5: return 10
        }
    }
}

/// Material 3 color scheme helpers
extension Color {
    // Primary colors
    public static let m3Primary = Color(r: 0.38, g: 0.49, b: 0.98, a: 1.0)  // Vibrant blue
    public static let m3OnPrimary = Color(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
    public static let m3PrimaryContainer = Color(r: 0.85, g: 0.90, b: 1.0, a: 1.0)
    public static let m3OnPrimaryContainer = Color(r: 0.0, g: 0.08, b: 0.35, a: 1.0)

    // Secondary colors
    public static let m3Secondary = Color(r: 0.36, g: 0.43, b: 0.58, a: 1.0)
    public static let m3OnSecondary = Color(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
    public static let m3SecondaryContainer = Color(r: 0.82, g: 0.87, b: 0.96, a: 1.0)
    public static let m3OnSecondaryContainer = Color(r: 0.05, g: 0.11, b: 0.22, a: 1.0)

    // Tertiary colors
    public static let m3Tertiary = Color(r: 0.49, g: 0.34, b: 0.62, a: 1.0)
    public static let m3OnTertiary = Color(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
    public static let m3TertiaryContainer = Color(r: 0.93, g: 0.87, b: 1.0, a: 1.0)
    public static let m3OnTertiaryContainer = Color(r: 0.15, g: 0.0, b: 0.25, a: 1.0)

    // Error colors
    public static let m3Error = Color(r: 0.73, g: 0.11, b: 0.11, a: 1.0)
    public static let m3OnError = Color(r: 1.0, g: 1.0, b: 1.0, a: 1.0)
    public static let m3ErrorContainer = Color(r: 0.98, g: 0.85, b: 0.84, a: 1.0)
    public static let m3OnErrorContainer = Color(r: 0.26, g: 0.0, b: 0.0, a: 1.0)

    // Surface colors
    public static let m3Surface = Color(r: 0.99, g: 0.99, b: 1.0, a: 1.0)
    public static let m3OnSurface = Color(r: 0.11, g: 0.11, b: 0.13, a: 1.0)
    public static let m3SurfaceVariant = Color(r: 0.88, g: 0.89, b: 0.94, a: 1.0)
    public static let m3OnSurfaceVariant = Color(r: 0.27, g: 0.28, b: 0.32, a: 1.0)

    // Outline
    public static let m3Outline = Color(r: 0.46, g: 0.47, b: 0.51, a: 1.0)
    public static let m3OutlineVariant = Color(r: 0.78, g: 0.79, b: 0.84, a: 1.0)
}

public struct Text: View, BuiltinView {
    var content: String
    var size: Float
    var color: Color
    var weight: FontWeight
    var family: String
    var lineLimit: Int?
    var alignment: TextAlignment
    var isItalic: Bool
    var underline: Bool
    var strikethrough: Bool
    var letterSpacing: Float

    public init(
        _ content: String,
        size: Float = 16,  // Default to M3 body size
        color: Color = .m3OnSurface,  // Default to M3 surface color
        weight: FontWeight = .regular,
        family: String = "Sans",
        lineLimit: Int? = nil,
        alignment: TextAlignment = .leading,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        letterSpacing: Float = 0
    ) {
        self.content = content
        self.size = size
        self.color = color
        self.weight = weight
        self.family = family
        self.lineLimit = lineLimit
        self.alignment = alignment
        self.isItalic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.letterSpacing = letterSpacing
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.text = content
        node.fontSize = size
        node.textColor = color
        node.fontFamily = family
        return node
    }

    // MARK: - Chainable Modifiers
    public func bold() -> Text {
        var copy = self
        copy.weight = .bold
        return copy
    }

    public func italic() -> Text {
        var copy = self
        copy.isItalic = true
        return copy
    }

    public func underline(_ active: Bool = true, color: Color? = nil) -> Text {
        var copy = self
        copy.underline = active
        return copy
    }

    public func strikethrough(_ active: Bool = true, color: Color? = nil) -> Text {
        var copy = self
        copy.strikethrough = active
        return copy
    }

    public func font(size: Float? = nil, weight: FontWeight? = nil, family: String? = nil) -> Text {
        var copy = self
        if let s = size { copy.size = s }
        if let w = weight { copy.weight = w }
        if let f = family { copy.family = f }
        return copy
    }

    public func foregroundColor(_ color: Color) -> Text {
        var copy = self
        copy.color = color
        return copy
    }

    public func lineLimit(_ limit: Int?) -> Text {
        var copy = self
        copy.lineLimit = limit
        return copy
    }

    public func multilineTextAlignment(_ alignment: TextAlignment) -> Text {
        var copy = self
        copy.alignment = alignment
        return copy
    }

    public func kerning(_ kerning: Float) -> Text {
        var copy = self
        copy.letterSpacing = kerning
        return copy
    }
}

public struct Rectangle: View, BuiltinView {
    var color: Color
    var w: Float
    var h: Float
    var cornerRadius: Float

    public init(color: Color = .black, w: Float = 100, h: Float = 100, cornerRadius: Float = 0) {
        self.color = color
        self.w = w
        self.h = h
        self.cornerRadius = cornerRadius
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: color)
        n.minW = w
        n.minH = h
        n.cornerRadius = cornerRadius
        return n
    }
}

public struct RoundedRectangle: View, BuiltinView {
    var cornerRadius: Float
    var color: Color

    public init(cornerRadius: Float, color: Color = .black) {
        self.cornerRadius = cornerRadius
        self.color = color
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: color)
        n.cornerRadius = cornerRadius
        return n
    }
}

public struct Capsule: View, BuiltinView {
    var color: Color

    public init(color: Color = .black) {
        self.color = color
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: color)
        n.shapeType = .circle
        return n
    }
}

public struct Circle: View, BuiltinView {
    var color: Color
    var size: Float

    public init(color: Color = .black, size: Float = 50) {
        self.color = color
        self.size = size
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: color)
        n.minW = size
        n.minH = size
        n.shapeType = .circle
        return n
    }
}

public struct Spacer: View, BuiltinView {
    var minLength: Float?

    public init(minLength: Float? = nil) {
        self.minLength = minLength
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: .clear)
        n.isSpacer = true
        if let min = minLength {
            n.minW = min
            n.minH = min
        }
        return n
    }
}

public struct Divider: View, BuiltinView {
    var color: Color
    var thickness: Float

    public init(color: Color = .m3OutlineVariant, thickness: Float = 1) {
        self.color = color
        self.thickness = thickness
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: color)
        n.minH = thickness
        return n
    }
}

public struct EmptyView: View, BuiltinView {
    public init() {}
    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: .clear)
        n.minW = 0
        n.minH = 0
        n.isHidden = true
        return n
    }
}

/// A view that fills available space with a color
public struct ColorView: View, BuiltinView {
    var color: Color

    public init(_ color: Color) {
        self.color = color
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        return Node(color: color)
    }
}
