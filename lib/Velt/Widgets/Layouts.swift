import Foundation

// ==========================================
// LAYOUT WIDGETS
// ==========================================

public struct VStack<Content: View>: View, BuiltinView {
    let content: Content
    let mainAxisAlignment: MainAxisAlignment
    let crossAxisAlignment: CrossAxisAlignment
    let spacing: Float

    public init(
        alignment: CrossAxisAlignment = .center,
        mainAxisAlignment: MainAxisAlignment = .start,
        spacing: Float = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.crossAxisAlignment = alignment
        self.mainAxisAlignment = mainAxisAlignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = .vStack
        node.mainAxisAlignment = mainAxisAlignment
        node.crossAxisAlignment = crossAxisAlignment

        let subIndex = composer.compose(content, key: "content")
        let subNode = subIndex.renderNode.node!

        if subNode.layoutType == .group {
            node.children = subNode.children
            // Apply spacing as marginTop to all children except first
            for (i, child) in node.children.enumerated() {
                if i > 0 { child.marginTop += spacing }
            }
        } else {
            node.children = [subNode]
        }
        return node
    }
}

public struct HStack<Content: View>: View, BuiltinView {
    let content: Content
    let mainAxisAlignment: MainAxisAlignment
    let crossAxisAlignment: CrossAxisAlignment
    let spacing: Float

    public init(
        alignment: CrossAxisAlignment = .center,
        mainAxisAlignment: MainAxisAlignment = .start,
        spacing: Float = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.crossAxisAlignment = alignment
        self.mainAxisAlignment = mainAxisAlignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = .hStack
        node.mainAxisAlignment = mainAxisAlignment
        node.crossAxisAlignment = crossAxisAlignment

        let subIndex = composer.compose(content, key: "content")
        let subNode = subIndex.renderNode.node!

        if subNode.layoutType == .group {
            node.children = subNode.children
            // Apply spacing as marginLeft to all children except first
            for (i, child) in node.children.enumerated() {
                if i > 0 { child.marginLeft += spacing }
            }
        } else {
            node.children = [subNode]
        }
        return node
    }
}

public struct ZStack<Content: View>: View, BuiltinView {
    let content: Content
    let alignment: Alignment

    public init(alignment: Alignment = .center, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = .zStack
        node.alignment = alignment

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

public struct Grid<Content: View>: View, BuiltinView {
    let columns: Int
    let spacing: Float
    let content: Content

    public init(columns: Int = 2, spacing: Float = 10, @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = .grid
        node.gridColumns = columns
        if let group = content as? _Fragment {
            node.children = group.children.map { $0.makeNode() }
        } else {
            node.children = [content.makeNode()]
        }
        return node
    }
}

/// Centers its content
public struct Center<Content: View>: View, BuiltinView {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = .zStack
        node.alignment = .center

        let subIndex = composer.compose(content, key: "content")
        node.children = [subIndex.renderNode.node!]
        return node
    }
}

/// A fixed-size box (Flutter-style)
public struct SizedBox: View, BuiltinView {
    var width: Float?
    var height: Float?

    public init(width: Float? = nil, height: Float? = nil) {
        self.width = width
        self.height = height
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let n = Node(color: .clear)
        if let w = width { n.minW = w }
        if let h = height { n.minH = h }
        return n
    }
}

// ==========================================
// MODIFIERS
// ==========================================

public struct ModifiedContent<Content: View>: View, BuiltinView {
    let content: Content
    let modifier: (Node) -> Void
    public var body: Never { fatalError() }
    func makeNode() -> Node {
        let node = content.makeNode()
        modifier(node)
        return node
    }
}

// ==========================================
// ANIMATION MODIFIER
// ==========================================

/// Storage for tracking animated properties per node
private var nodeAnimationIds: [ObjectIdentifier: UUID] = [:]

extension View {
    /// Apply animation to color changes
    public func animation(_ animation: Animation = .default) -> AnimatedView<Self> {
        AnimatedView(content: self, animation: animation)
    }
}

/// A view wrapper that animates property changes
public struct AnimatedView<Content: View>: View, BuiltinView {
    let content: Content
    let animation: Animation

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = content.makeNode()
        node.animationConfig = animation
        return node
    }
}
