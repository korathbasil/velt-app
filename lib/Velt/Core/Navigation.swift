import Foundation

// ==========================================
// NAVIGATION ENGINE - High Performance
// ==========================================

/// A single screen entry in the navigation stack
public struct ScreenEntry {
    public let id: UUID
    public let key: AnyHashable
    public let view: AnyView
    public let renderNode: RenderNode
    public let composer: Composer
}

/// The high-performance navigation coordinator
public final class Navigator: ObservableObject {
    public static let shared = Navigator()

    /// The actual stack of screen entries
    @Published private(set) public var stack: [ScreenEntry] = []

    /// Screen width for animations (synced from engine)
    public var screenWidth: Float = 360

    public override init() {
        super.init()
    }

    // MARK: - API

    /// Initialize the navigation stack with a root view
    public func setRoot<V: View>(_ view: V) {
        stack.removeAll()

        let anyView = AnyView(view)  // Type erasure for consistent slot keying

        let c = Composer()
        c.startComposition()
        let (_, node) = c.compose(anyView, key: "nav_root")
        c.endComposition()

        let entry = ScreenEntry(
            id: UUID(),
            key: "nav_root",
            view: anyView,
            renderNode: node,
            composer: c
        )

        stack.append(entry)
        needsRender = true
    }

    /// Push a new screen with parallax animation
    public func push<V: View>(_ view: V, key: AnyHashable? = nil) {
        let uniqueKey = key ?? AnyHashable(UUID())
        let anyView = AnyView(view)

        // 1. Compose the new screen with a FRESH Composer
        let c = Composer()
        c.startComposition()
        let (_, node) = c.compose(anyView, key: uniqueKey)
        c.endComposition()

        let newEntry = ScreenEntry(
            id: UUID(),
            key: uniqueKey,
            view: anyView,
            renderNode: node,
            composer: c
        )

        // 2. Prepare Parallax on previous screen if any
        if let previous = stack.last {
            AnimationController.shared.animate(
                from: previous.renderNode.paintOffsetX,
                to: -screenWidth * 0.2,  // Subtle parallax
                animation: .easeOut(duration: 0.35)
            ) { val in
                previous.renderNode.paintOffsetX = val
            }
        }

        // 3. Prepare Push Animation on new screen
        node.paintOffsetX = screenWidth
        AnimationController.shared.animate(
            from: screenWidth,
            to: 0,
            animation: .easeOut(duration: 0.35)
        ) { val in
            node.paintOffsetX = val
            needsRender = true
        }

        stack.append(newEntry)
        needsRender = true
        self.objectWillChange()
    }

    /// Pop the top screen with slide-out animation
    public func pop() {
        guard stack.count > 1 else { return }

        let top = stack.removeLast()
        let previous = stack.last!

        // 1. Slide top screen out
        AnimationController.shared.animate(
            from: top.renderNode.paintOffsetX,
            to: screenWidth,
            animation: .easeOut(duration: 0.3)
        ) { val in
            top.renderNode.paintOffsetX = val
            needsRender = true
        } completion: {
            // Screen is now fully out, it's already removed from stack
            needsRender = true
        }

        // 2. Slide previous screen back in (parallax)
        AnimationController.shared.animate(
            from: previous.renderNode.paintOffsetX,
            to: 0,
            animation: .easeOut(duration: 0.3)
        ) { val in
            previous.renderNode.paintOffsetX = val
        }

        self.objectWillChange()
        needsRender = true
    }

    public func popToRoot() {
        while stack.count > 1 {
            pop()
        }
    }
}

// ==========================================
// NAVIGATION STACK - DSL Wrapper
// ==========================================

public struct NavigationStack<Content: View>: View, BuiltinView {
    let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: Never { fatalError() }

    public func makeNode() -> Node {
        // NavigationStack is now a shell. The Navigator manages the RenderNodes.
        // We just return a clear node to keep the tree valid.
        // The Application loop handles the actual stack rendering.
        let node = Node(color: .clear)
        node.layoutType = .group

        // One-time initialization of Navigator if empty
        if Navigator.shared.stack.isEmpty {
            Navigator.shared.setRoot(content())
        }

        return node
    }
}

// ==========================================
// NAVIGATION LINK
// ==========================================

public struct NavigationLink<Label: View, D: Hashable>: View {
    let value: D
    let label: () -> Label

    public init(value: D, @ViewBuilder label: @escaping () -> Label) {
        self.value = value
        self.label = label
    }

    public var body: some View {
        label()
            .onTapGesture {
                // Determine destination from registry
                let typeID = ObjectIdentifier(type(of: value))
                if let builder = NavigationRegistry.shared.builders[typeID] {
                    let destination = builder(value)
                    Navigator.shared.push(destination, key: AnyHashable(value))
                }
            }
    }
}

// ==========================================
// REGISTRY
// ==========================================

public class NavigationRegistry {
    public static let shared = NavigationRegistry()
    public var builders: [ObjectIdentifier: (Any) -> AnyView] = [:]

    private init() {}

    public func register<D: Hashable, V: View>(_ type: D.Type, builder: @escaping (D) -> V) {
        builders[ObjectIdentifier(type)] = { val in
            AnyView(builder(val as! D))
        }
    }
}
