import Foundation

// ==========================================
// CARD WIDGETS
// ==========================================

/// Base Material 3 Card
public struct Card<Content: View>: View, BuiltinView {
    let content: Content
    let elevation: Elevation
    let bgColor: Color
    let cornerRadius: Float

    public init(
        elevation: Elevation = .level1,
        bgColor: Color = .m3Surface,
        cornerRadius: Float = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.bgColor = bgColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: bgColor)
        node.padding = 16
        node.cornerRadius = cornerRadius
        node.shadowColor = Color(r: 0, g: 0, b: 0, a: elevation.shadowAlpha)
        node.shadowBlur = elevation.shadowBlur
        node.shadowY = elevation.shadowOffset
        node.layoutType = .vStack

        let subIndex = composer.compose(content, key: "content")
        let subNode = subIndex.renderNode.node!

        if subNode.layoutType == .group {
            node.children = subNode.children
        } else {
            node.children = [subNode]
        }
        return node
    }
}

/// Elevated Card with prominent shadow
public struct ElevatedCard<Content: View>: View {
    let content: Content
    let bgColor: Color

    public init(
        bgColor: Color = .m3Surface,
        @ViewBuilder content: () -> Content
    ) {
        self.bgColor = bgColor
        self.content = content()
    }

    public var body: some View {
        Card(elevation: .level1, bgColor: bgColor) {
            content
        }
    }
}

/// Filled Card with tonal background
public struct FilledCard<Content: View>: View {
    let content: Content
    let bgColor: Color

    public init(
        bgColor: Color = .m3SurfaceVariant,
        @ViewBuilder content: () -> Content
    ) {
        self.bgColor = bgColor
        self.content = content()
    }

    public var body: some View {
        Card(elevation: .level0, bgColor: bgColor) {
            content
        }
    }
}

/// Outlined Card with border
public struct OutlinedCard<Content: View>: View, BuiltinView {
    let content: Content
    let borderColor: Color

    public init(
        borderColor: Color = .m3OutlineVariant,
        @ViewBuilder content: () -> Content
    ) {
        self.borderColor = borderColor
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .m3Surface)
        node.padding = 16
        node.cornerRadius = 12
        node.borderColor = borderColor
        node.borderWidth = 1
        node.layoutType = .vStack

        let subIndex = composer.compose(content, key: "content")
        let subNode = subIndex.renderNode.node!

        if subNode.layoutType == .group {
            node.children = subNode.children
        } else {
            node.children = [subNode]
        }
        return node
    }
}
