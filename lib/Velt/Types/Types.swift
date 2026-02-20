import Foundation

// ==========================================
// EDGE & ALIGNMENT TYPES
// ==========================================

/// Individual edges
public enum Edge: CaseIterable {
    case top, leading, bottom, trailing
}

/// Edge sets for padding/margin
public struct EdgeSet: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let top = EdgeSet(rawValue: 1 << 0)
    public static let leading = EdgeSet(rawValue: 1 << 1)
    public static let bottom = EdgeSet(rawValue: 1 << 2)
    public static let trailing = EdgeSet(rawValue: 1 << 3)

    public static let horizontal: EdgeSet = [.leading, .trailing]
    public static let vertical: EdgeSet = [.top, .bottom]
    public static let all: EdgeSet = [.top, .leading, .bottom, .trailing]
}

/// Edge insets (padding/margin values)
public struct EdgeInsets: Equatable {
    public var top: Float
    public var leading: Float
    public var bottom: Float
    public var trailing: Float

    public init(top: Float = 0, leading: Float = 0, bottom: Float = 0, trailing: Float = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    public init(_ all: Float) {
        self.top = all
        self.leading = all
        self.bottom = all
        self.trailing = all
    }

    public init(horizontal: Float = 0, vertical: Float = 0) {
        self.top = vertical
        self.leading = horizontal
        self.bottom = vertical
        self.trailing = horizontal
    }

    public static let zero = EdgeInsets()
}

// ==========================================
// ALIGNMENT TYPES
// ==========================================

/// Horizontal alignment
public enum HorizontalAlignment {
    case leading, center, trailing
}

/// Vertical alignment
public enum VerticalAlignment {
    case top, center, bottom
}

/// Combined alignment
public struct Alignment2D: Equatable {
    public var horizontal: HorizontalAlignment
    public var vertical: VerticalAlignment

    public init(horizontal: HorizontalAlignment = .center, vertical: VerticalAlignment = .center) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public static let topLeading = Alignment2D(horizontal: .leading, vertical: .top)
    public static let top = Alignment2D(horizontal: .center, vertical: .top)
    public static let topTrailing = Alignment2D(horizontal: .trailing, vertical: .top)
    public static let leading = Alignment2D(horizontal: .leading, vertical: .center)
    public static let center = Alignment2D(horizontal: .center, vertical: .center)
    public static let trailing = Alignment2D(horizontal: .trailing, vertical: .center)
    public static let bottomLeading = Alignment2D(horizontal: .leading, vertical: .bottom)
    public static let bottom = Alignment2D(horizontal: .center, vertical: .bottom)
    public static let bottomTrailing = Alignment2D(horizontal: .trailing, vertical: .bottom)
}

/// Main Axis Alignment (for Stacks)
public enum MainAxisAlignment {
    case start, center, end, spaceBetween, spaceAround, spaceEvenly

    // Compatibility aliases
    public static let leading = start
    public static let trailing = end
    public static let top = start
    public static let bottom = end
}

/// Cross Axis Alignment (for Stacks)
public enum CrossAxisAlignment {
    case start, center, end, stretch

    // Compatibility aliases
    public static let leading = start
    public static let trailing = end
    public static let top = start
    public static let bottom = end
}

// ==========================================
// CONTENT MODE
// ==========================================

/// How content should be sized within its bounds
public enum ContentMode {
    case fit  // Scale to fit, maintaining aspect ratio (may letterbox)
    case fill  // Scale to fill, maintaining aspect ratio (may crop)
    case stretch  // Stretch to fill (ignores aspect ratio)
}

// ==========================================
// TEXT TYPES
// ==========================================

/// Text alignment
public enum TextAlignment {
    case leading, center, trailing
}

/// Font weight
public enum FontWeight: String {
    case ultraLight = "UltraLight"
    case thin = "Thin"
    case light = "Light"
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "Semibold"
    case bold = "Bold"
    case heavy = "Heavy"
    case black = "Black"
}

// ==========================================
// AXIS
// ==========================================

/// Axis for scrolling/layout
public enum Axis {
    case horizontal, vertical
}

/// Axis set for multi-directional scrolling
public struct AxisSet: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let horizontal = AxisSet(rawValue: 1 << 0)
    public static let vertical = AxisSet(rawValue: 1 << 1)
    public static let both: AxisSet = [.horizontal, .vertical]
}

// ==========================================
// BLEND MODES
// ==========================================

/// Blend modes for compositing
public enum BlendMode {
    case normal
    case multiply
    case screen
    case overlay
    case darken
    case lighten
    case colorDodge
    case colorBurn
    case softLight
    case hardLight
    case difference
    case exclusion
}

// ==========================================
// TOGGLE SIZE
// ==========================================

public enum ToggleSize {
    case mini  // 40x24
    case small  // 44x26
    case regular  // 50x30
    case large  // 60x36

    var trackWidth: Float {
        switch self {
        case .mini: return 40
        case .small: return 44
        case .regular: return 50
        case .large: return 60
        }
    }

    var trackHeight: Float {
        switch self {
        case .mini: return 24
        case .small: return 26
        case .regular: return 30
        case .large: return 36
        }
    }
}
