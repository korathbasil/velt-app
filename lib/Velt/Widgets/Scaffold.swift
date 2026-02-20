import Foundation

// ==========================================
// SCAFFOLD - Standard Screen Structure
// ==========================================

public struct Scaffold<TopBar: View, Content: View>: View {
    let topBar: TopBar
    let backgroundColor: Color
    let content: Content

    public init(
        backgroundColor: Color = .white,
        @ViewBuilder topBar: () -> TopBar,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.topBar = topBar()
        self.content = content()
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // 1. Background Layer
            Rectangle(color: backgroundColor, w: 1000, h: 2000)

            // 2. Main Layout
            VStack(alignment: .center) {
                // Top Bar
                topBar

                // Content Body
                content

                Spacer()
            }
        }
    }
}

// Convenience init for optional TopBar (Defaults to EmptyView)
extension Scaffold where TopBar == EmptyView {
    public init(
        backgroundColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.topBar = EmptyView()
        self.content = content()
    }
}
