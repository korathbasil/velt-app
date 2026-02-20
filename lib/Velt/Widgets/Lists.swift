import Foundation

// ==========================================
// LIST WIDGETS
// ==========================================

public struct ListTile<Leading: View, Trailing: View>: View, BuiltinView {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing
    let onTap: (() -> Void)?

    // M3 Defaults
    let titleColor: Color = .m3OnSurface
    let subtitleColor: Color = .m3OnSurfaceVariant

    // Direct init (bypasses ViewBuilder logic)
    public init(
        title: String,
        subtitle: String? = nil,
        leading: Leading,
        trailing: Trailing,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading
        self.trailing = trailing
        self.onTap = onTap
    }

    // Builder init
    public init(
        title: String,
        subtitle: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            leading: leading(),
            trailing: trailing(),
            onTap: onTap
        )
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        // Root node acts as container (ZStack) to hold content + ripple
        let rootNode = Node(color: .clear)
        rootNode.layoutType = .zStack
        rootNode.alignment = .center
        rootNode.onClick = onTap

        // Content Node (HStack)
        let contentNode = Node(color: .clear)
        contentNode.padding = 16
        contentNode.layoutType = .hStack
        contentNode.alignment = .center

        var children: [Node] = []

        // Leading
        let leadingNode = leading.makeNode()
        if !leadingNode.isHidden {
            leadingNode.marginRight = 16
            children.append(leadingNode)
        }

        // Content (Title + Subtitle)
        let textContainer = Node(color: .clear)
        textContainer.layoutType = .vStack
        textContainer.alignment = .leading

        let titleNode = Node(color: .clear)
        titleNode.text = title
        titleNode.textColor = titleColor
        titleNode.fontSize = 16

        var textChildren: [Node] = [titleNode]

        if let subtitle = subtitle {
            let subtitleNode = Node(color: .clear)
            subtitleNode.text = subtitle
            subtitleNode.textColor = subtitleColor
            subtitleNode.fontSize = 14
            subtitleNode.marginTop = 4
            textChildren.append(subtitleNode)
        }
        textContainer.children = textChildren
        children.append(textContainer)

        // Spacer
        let spacer = Node(color: .clear)
        spacer.isSpacer = true
        children.append(spacer)

        // Trailing
        let trailingNode = trailing.makeNode()
        if !trailingNode.isHidden {
            trailingNode.marginLeft = 16
            children.append(trailingNode)
        }

        contentNode.children = children
        rootNode.children = [contentNode]

        // Interaction Feedback (Ripple)
        if onTap != nil {
            rootNode.onPress = { [weak rootNode] in
                guard let rootNode = rootNode else { return }
                RippleEffect.addRipple(to: rootNode, color: Color(r: 0, g: 0, b: 0, a: 0.1))
            }
        }

        return rootNode
    }
}

// Convenience extension for when Leading/Trailing are omitted
extension ListTile where Leading == EmptyView, Trailing == EmptyView {
    public init(
        title: String,
        subtitle: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            leading: EmptyView(),
            trailing: EmptyView(),
            onTap: onTap
        )
    }
}

// Convenience extension for just Leading
extension ListTile where Trailing == EmptyView {
    public init(
        title: String,
        subtitle: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder leading: () -> Leading
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            leading: leading(),
            trailing: EmptyView(),
            onTap: onTap
        )
    }
}

// Convenience extension for just Trailing
extension ListTile where Leading == EmptyView {
    public init(
        title: String,
        subtitle: String? = nil,
        onTap: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            leading: EmptyView(),
            trailing: trailing(),
            onTap: onTap
        )
    }
}
