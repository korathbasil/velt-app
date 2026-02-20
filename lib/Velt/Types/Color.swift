public struct Color: Equatable {
    let r: Float, g: Float, b: Float, a: Float
    public static let red = Color(r: 1.0, g: 0.23, b: 0.19, a: 1)
    public static let green = Color(r: 0.20, g: 0.78, b: 0.35, a: 1)
    public static let blue = Color(r: 0.0, g: 0.48, b: 1.0, a: 1)
    public static let white = Color(r: 1, g: 1, b: 1, a: 1)
    public static let black = Color(r: 0, g: 0, b: 0, a: 1)
    public static let gray = Color(r: 0.55, g: 0.55, b: 0.57, a: 1)
    public static let lightGray = Color(r: 0.93, g: 0.93, b: 0.94, a: 1)
    public static let darkGray = Color(r: 0.11, g: 0.11, b: 0.12, a: 1)
    public static let clear = Color(r: 0, g: 0, b: 0, a: 0)
    public static let orange = Color(r: 1.0, g: 0.58, b: 0.0, a: 1)
    public static let purple = Color(r: 0.68, g: 0.32, b: 0.87, a: 1)

    public init(r: Float, g: Float, b: Float, a: Float = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    public func opacity(_ alpha: Float) -> Color {
        return Color(r: r, g: g, b: b, a: alpha)
    }
}
