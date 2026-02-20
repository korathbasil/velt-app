// ==========================================
// SCROLLVIEW
// ==========================================

public struct ScrollView<Content: View>: View, BuiltinView {
    @State var offset: Float = 0
    let content: Content
    let axis: Axis
    let showsIndicators: Bool

    public var body: Never { fatalError() }

    public init(
        _ axis: Axis = .vertical,
        showsIndicators: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.axis = axis
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    public func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = .scroll
        node.scrollAxis = axis
        node.scrollOffset = offset

        // Capture node weakly to update scrollOffset directly for immediate visual feedback
        node.onScroll = { [weak node] (dx: Float, dy: Float) in
            guard let node = node else { return }

            let sensitivity: Float = 20.0

            if self.axis == .vertical {
                var newOffset = node.scrollOffset - (dy * sensitivity)
                if newOffset < 0 { newOffset = 0 }
                // Clamp to max content height
                let maxScroll = max(0, (node.children.first?.frame.h ?? 0) - node.frame.h)
                if newOffset > maxScroll { newOffset = maxScroll }
                node.scrollOffset = newOffset
                // self.offset = newOffset  // performance: avoid triggering state update during scroll
            } else {
                var newOffset = node.scrollOffset - (dx * sensitivity)
                if newOffset < 0 { newOffset = 0 }
                let maxScroll = max(0, (node.children.first?.frame.w ?? 0) - node.frame.w)
                if newOffset > maxScroll { newOffset = maxScroll }
                node.scrollOffset = newOffset
                // self.offset = newOffset // performance: avoid triggering state update during scroll
            }
        }

        node.children = [content.makeNode()]
        return node
    }
}
