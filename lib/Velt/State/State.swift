import Foundation

// ==========================================
// STATE MANAGEMENT SYSTEM
// ==========================================

/// Global flag to indicate a render is needed
public var needsRender: Bool = true

/// Observable protocol for objects that can notify observers of changes
public protocol Observable: AnyObject {
    var observers: [() -> Void] { get set }
    func notifyObservers()
}

extension Observable {
    public func notifyObservers() {
        needsRender = true
        observers.forEach { $0() }
    }
}

/// A property wrapper that stores a value persistently in the SlotTable.
@propertyWrapper
public struct State<Value> {
    private let initialValue: Value

    // Internal reference type to cache the resolved StateBox AND Composer.
    // This maintains context for the state even when accessed outside `body` (e.g. actions).
    private class Storage {
        var box: StateBox<Value>?
        weak var composer: Composer?
    }
    private let storage = Storage()

    public init(wrappedValue: Value) {
        self.initialValue = wrappedValue
    }

    private var box: StateBox<Value> {
        // 1. Return cached box if available (fast path + persistent access outside composition)
        if let b = storage.box { return b }

        // 2. Resolve from SlotTable during composition
        guard let st = SlotTable.current else {
            // Fallback: If accessed outside composition and NEVER rendered, we return ephemeral.
            // This generally shouldn't happen for active State variables.
            return StateBox(value: initialValue)
        }

        // 3. Remember and Cache
        let b = st.remember { StateBox(value: initialValue) }
        storage.box = b
        storage.composer = st.composer
        return b
    }

    public var wrappedValue: Value {
        get {
            // Track dependency using the CURRENT COMPOSER'S graph
            let b = box  // Ensure box is resolved
            if let d = SlotTable.current?.composer?.depGraph {
                d.trackRead(state: b)
            } else {
                // Fallback: No dependency graph available.
                // This can happen if State is read outside of a composable context.
            }
            return b.value
        }
        nonmutating set {
            let b = box  // Resolve box (uses cache if outside composition)
            b.value = newValue
            // Notify specific composer
            if let c = storage.composer {
                c.notifyStateChanged(b)
            } else {
                composer.notifyStateChanged(b)
            }
            needsRender = true
        }
    }

    public var projectedValue: Binding<Value> {
        let b = box  // Capture box eagerly
        let c = storage.composer  // Capture composer
        return Binding(
            get: {
                if let d = c?.depGraph {
                    d.trackRead(state: b)
                }
                return b.value
            },
            set: {
                b.value = $0
                if let comp = c {
                    comp.notifyStateChanged(b)
                } else {
                    composer.notifyStateChanged(b)
                }
                needsRender = true
            }
        )
    }
}

/// Internal box to hold state in SlotTable. Marked as AnyObject for dependency graph.
private class StateBox<Value> {
    var value: Value
    init(value: Value) { self.value = value }
}

// ==========================================
// @BINDING PROPERTY WRAPPER
// ==========================================

/// A property wrapper for two-way data binding.
/// Similar to SwiftUI's @Binding.
@propertyWrapper
public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void

    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        self.getter = get
        self.setter = set
    }

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }

    public var projectedValue: Binding<Value> { self }

    /// Create a constant (read-only) binding
    public static func constant(_ value: Value) -> Binding<Value> {
        Binding(get: { value }, set: { _ in })
    }
}

// ==========================================
// OBSERVABLE OBJECT
// ==========================================

/// A base class for observable objects (similar to SwiftUI's ObservableObject)
open class ObservableObject: Observable {
    public var observers: [() -> Void] = []

    public init() {}

    /// Call this when a property changes to trigger a re-render
    public func objectWillChange() {
        notifyObservers()
    }
}

// ==========================================
// @PUBLISHED PROPERTY WRAPPER
// ==========================================

/// A property wrapper that publishes changes to its value.
/// Use inside ObservableObject subclasses.
/// Integrates with the dependency graph for fine-grained invalidation.
@propertyWrapper
public class Published<Value> {
    private var value: Value

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            // Track that this state was read (for dependency graph)
            dependencyGraph.trackRead(state: self)
            return value
        }
        set {
            value = newValue
            // Invalidate only slots that depend on this state
            composer.notifyStateChanged(self)
            needsRender = true
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: {
                dependencyGraph.trackRead(state: self)
                return self.value
            },
            set: {
                self.value = $0
                composer.notifyStateChanged(self)
                needsRender = true
            }
        )
    }
}

// ==========================================
// @OBSERVEDOBJECT PROPERTY WRAPPER
// ==========================================

/// A property wrapper that subscribes to an observable object and triggers re-renders.
/// Similar to SwiftUI's @ObservedObject.
@propertyWrapper
public struct ObservedObject<ObjectType: ObservableObject> {
    public var wrappedValue: ObjectType

    public init(wrappedValue: ObjectType) {
        self.wrappedValue = wrappedValue

        // During composition, subscribe this slot to the object
        if let slot = SlotTable.currentSlotIndex {
            wrappedValue.observers.append {
                composer.notifySlotDirty(slot)
            }
        }
    }
}

// ==========================================
// FOR EACHVIEW
// ==========================================

public struct ForEach<Data, ID, Content>: View, BuiltinView
where Data: RandomAccessCollection, ID: Hashable, Content: View {
    public let data: Data
    public let content: (Data.Element) -> Content
    public var layout: LayoutType = .vStack

    public init(
        _ data: Data, id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
    }

    // Range-based init
    public init(_ range: Range<Int>, @ViewBuilder content: @escaping (Int) -> Content)
    where Data == Range<Int>, ID == Int {
        self.data = range
        self.content = content
    }

    public func layout(_ type: LayoutType) -> ForEach {
        var copy = self
        copy.layout = type
        return copy
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = self.layout

        node.children = data.enumerated().map { (i, item) in
            // Use the data's ID if possible, or fallback to index
            // Note: In a real impl we'd use KeyPath but for now index is safer
            composer.compose(content(item), key: i).renderNode.node!
        }
        return node
    }
}
