import Foundation
import ImpellerBackend

// ==========================================
// COMPOSER - Orchestrates Composition
// ==========================================
// Manages the composition process, integrating slot table and dependency graph.
// Handles smart recomposition with memoization.

/// The Composer orchestrates UI composition and recomposition
public class Composer {
    /// The slot table for storing composition state
    public let slotTable: SlotTable

    /// The dependency graph for tracking state dependencies
    public let depGraph: DependencyGraph

    /// Set of slot indices that need recomposition
    public private(set) var dirtySlots: Set<Int> = []

    /// Whether we're currently in a composition pass
    public private(set) var isComposing: Bool = false

    /// The render nodes created during composition
    public var renderNodes: [RenderNode] = []

    /// Root render node
    public var rootRenderNode: RenderNode?

    public init() {
        self.slotTable = SlotTable()
        self.depGraph = DependencyGraph()  // Use specialized instance
        self.depGraph.connect(to: slotTable)
        self.slotTable.composer = self
    }

    // MARK: - Composition API

    /// Begin a full composition pass
    public func startComposition() {
        isComposing = true
        slotTable.startComposition()
        SlotTable.current = slotTable
        dirtySlots.removeAll()
    }

    /// End the composition pass
    public func endComposition() {
        slotTable.endComposition()
        SlotTable.current = nil
        isComposing = false
    }

    /// Compose a view at the current position
    /// Returns the slot index and render node
    @discardableResult
    public func compose<V: View>(
        _ view: V,
        key: AnyHashable? = nil
    ) -> (slotIndex: Int, renderNode: RenderNode) {
        // Generate key from view type if not provided
        let compositionKey = key ?? AnyHashable(String(describing: type(of: view)))
        let viewTypeName = String(describing: type(of: view))

        // Begin group in slot table
        let (slotIndex, isNew) = slotTable.beginGroup(key: compositionKey, viewType: viewTypeName)

        // Start dependency tracking for this slot
        depGraph.startTracking(slot: slotIndex)

        // Create or reuse render node
        let renderNode: RenderNode
        if isNew {
            renderNode = RenderNode()
            renderNode.slotIndex = slotIndex
            renderNodes.append(renderNode)
            slotTable.updateSlot(at: slotIndex) { slot in
                slot.renderNodeIndex = renderNodes.count - 1
            }
        } else if let existingIndex = slotTable.slot(at: slotIndex)?.renderNodeIndex,
            existingIndex < renderNodes.count
        {
            renderNode = renderNodes[existingIndex]
        } else {
            renderNode = RenderNode()
            renderNode.slotIndex = slotIndex
            renderNodes.append(renderNode)
        }

        // Build the node from the view
        let node = view.makeNode()
        renderNode.update(from: node)

        // Stop dependency tracking
        depGraph.stopTracking()

        // Clear dirty flag
        slotTable.clearDirty(slotIndex: slotIndex)

        // End group
        slotTable.endGroup()

        return (slotIndex, renderNode)
    }

    /// Remember a value in the current composition scope
    public func remember<T>(key: AnyHashable = "default", calculation: () -> T) -> T {
        return slotTable.remember(key: key, calculation: calculation)
    }

    /// Check if inputs changed (for skip optimization)
    public func changed<T: Equatable>(_ value: T, key: AnyHashable = "input") -> Bool {
        return slotTable.changed(value, key: key)
    }

    // MARK: - Recomposition

    /// Mark a state as changed, triggering recomposition of dependent slots
    public func notifyStateChanged<T: AnyObject>(_ state: T) {
        let affected = depGraph.invalidate(state: state)
        dirtySlots.formUnion(affected)
        needsRender = true
    }

    /// Directly mark a slot as dirty
    public func notifySlotDirty(_ slot: Int) {
        dirtySlots.insert(slot)
        needsRender = true
    }

    /// Recompose only dirty slots
    public func recomposeDirty<V: View>(rootView: V, key: AnyHashable = "root") {
        // Fast path: check if anything is actually dirty without building arrays
        let hasDirty = !dirtySlots.isEmpty || slotTable.hasDirtySlots()
        if !hasDirty { return }

        // Track metrics
        RenderMetrics.current.recompositionCount += 1

        // For now, if anything is dirty, recompose everything.
        // In the future, we will implement optimized partial recomposition.
        startComposition()
        let (_, node) = compose(rootView, key: key)
        if key == AnyHashable("root") {
            rootRenderNode = node
        }
        endComposition()

        // Clear dirty flags - only clear what we know is dirty
        dirtySlots.removeAll(keepingCapacity: true)
    }

    /// Get the current dirty slot count (for debugging/metrics)
    public var dirtyCount: Int {
        return dirtySlots.count
    }
}

// ==========================================
// RENDER NODE - Layout/Paint with Dirty Marking
// ==========================================

/// A render node handles layout and painting with dirty marking
public class RenderNode {
    /// The slot this render node is associated with
    public var slotIndex: Int = -1

    /// Frame in parent coordinates
    public var frame: (x: Float, y: Float, w: Float, h: Float) = (0, 0, 0, 0)

    /// Absolute frame for hit testing
    public var absFrame: (x: Float, y: Float, w: Float, h: Float) = (0, 0, 0, 0)

    /// Fast-path transforms (Painting only, no layout)
    public var paintOffsetX: Float = 0
    public var paintOffsetY: Float = 0

    /// Lifecycle
    private var didAppear: Bool = false

    // Generic Animated Properties
    private var animatedColor: Color?
    private var colorAnimationId: UUID?

    // Generic Float Animations (supports minW, minH, margins, etc.)
    internal var animatedFloats: [String: Float] = [:]
    private var floatAnimationIds: [String: UUID] = [:]

    // Keys to check for float animations
    private static let performantFloatKeys = [
        "minW", "minH",
        "marginLeft", "marginTop", "marginRight", "marginBottom",
        "cornerRadius", "borderWidth", "padding", "fontSize",
    ]

    /// Whether layout needs to be recalculated
    public var needsLayout: Bool = true

    /// Whether painting needs to be redone
    public var needsPaint: Bool = true

    /// Is this a layout boundary (stops dirty propagation)
    public var isLayoutBoundary: Bool = false

    /// Children render nodes
    public var children: [RenderNode] = []

    /// Parent render node
    public weak var parent: RenderNode?

    /// The underlying node data (from View.makeNode())
    private var nodeData: Node?

    public init() {}

    public func update(from node: Node) {
        // 1. Color Animation (Special case)
        if let existing = nodeData, let config = node.animationConfig {
            if existing.color != node.color {
                startColorAnimation(
                    from: animatedColor ?? existing.color, to: node.color,
                    config: config)
            }
        } else {
            animatedColor = node.color
        }

        // 2. Generic Float Animations
        let config = node.animationConfig
        if let existing = nodeData, config != nil {
            for key in RenderNode.performantFloatKeys {
                let oldVal = getFloatValue(node: existing, key: key)
                let newVal = getFloatValue(node: node, key: key)

                if oldVal != newVal {
                    if let animConfig = config {
                        let fromVal = animatedFloats[key] ?? oldVal
                        startFloatAnimation(
                            key: key,
                            from: fromVal,
                            to: newVal,
                            config: animConfig
                        )
                    } else {
                        // Value changed but NO animation config! Just sync.
                        animatedFloats[key] = newVal
                    }
                }
            }
        } else {
            // First time: just sync values to animatedFloats as initial state
            for key in RenderNode.performantFloatKeys {
                let v = getFloatValue(node: node, key: key)
                animatedFloats[key] = v
            }
        }

        nodeData = node

        // Lifecycle: trigger onAppear if first time
        if !didAppear {
            node.onAppear?()
            didAppear = true
        }

        markNeedsLayout()
        markNeedsPaint()

        // Recursively update children (Reuse existing RenderNodes to persist state!)
        var newChildren: [RenderNode] = []
        for (i, childNode) in node.children.enumerated() {
            let childRender: RenderNode
            if i < children.count {
                childRender = children[i]
            } else {
                childRender = RenderNode()
                childRender.parent = self
            }
            childRender.update(from: childNode)
            newChildren.append(childRender)
        }
        children = newChildren
    }

    /// Mark this node as needing layout
    public func markNeedsLayout() {
        needsLayout = true

        // Propagate up unless we hit a boundary
        if !isLayoutBoundary {
            parent?.markNeedsLayout()
        }
    }

    /// Mark this node as needing paint
    public func markNeedsPaint() {
        needsPaint = true
        // Paint doesn't propagate up (only affects this subtree)
    }

    /// Perform layout if needed
    public func performLayout(maxWidth: Float, maxHeight: Float) {
        guard let node = nodeData else { return }

        // Dirty check: optimization to skip layout if nothing changed
        if !needsLayout && frame.w == frame.w && frame.h == frame.h {
            // We also need to check if constraints changed (maxWidth/maxHeight)
            // But simple check:
            // return
            // Actually, layout depends on incoming constraints.
            // If constraints changed, we MUST layout even if !needsLayout.
            // For now, let's assume if constraints are same and !needsLayout, we skip.
            // But we don't track prevConstraints here.
            // Let's rely on caller not calling us?
            // Or better: Application.swift shouldn't force it.
            // But protection here is good.
        }

        // Temporarily, let's just NOT force it in Application.swift
        // But we DO need to reset `needsLayout = false` at the end!
        // The current code DOES NOT seem to set needsLayout = false!
        // Wait, let's check the end of the method.

        // 1. Apply Self Animations (Generic) to our underlying node
        var selfRestores: [(String, Float)] = []
        for (key, val) in animatedFloats {
            let original = getFloatValue(node: node, key: key)
            selfRestores.append((key, original))
            setFloatValue(node: node, key: key, value: val)
        }

        // Apply Color self animation
        let originalColor = node.color
        if let animColor = animatedColor {
            node.color = animColor
        }

        // 2. CRITICAL: For each child, apply its animated properties to its underlying node
        // BEFORE we call node.layout(). This ensures the parent's layout pass (which positions children)
        // sees the current animated margin/size for each child.
        var allChildRestores: [[(String, Float)]] = Array(repeating: [], count: node.children.count)
        for (i, childRender) in children.enumerated() {
            if i < node.children.count {
                let childNode = node.children[i]
                for (key, val) in childRender.animatedFloats {
                    let original = getFloatValue(node: childNode, key: key)
                    allChildRestores[i].append((key, original))
                    setFloatValue(node: childNode, key: key, value: val)
                }
            }
        }

        // 3. Delegate to the node's layout (using animated properties of self and children)
        let size = node.layout(maxWidth: maxWidth, maxHeight: maxHeight)
        frame = (frame.x, frame.y, size.w, size.h)

        // 5. Layout children recursively
        for (index, child) in children.enumerated() {
            if index < node.children.count {
                let childNode = node.children[index]
                child.frame = childNode.frame
            }
            child.performLayout(maxWidth: child.frame.w, maxHeight: child.frame.h)
        }

        // 6. Special Case: Navigator Layout
        if node.layoutType == .navigator, let nav = node.navigator {
            // Layout all screens in the stack (only visible ones usually, but stacks are small)
            // Stacks fill the navigator frame
            for screen in nav.stack {
                screen.renderNode.performLayout(maxWidth: frame.w, maxHeight: frame.h)
                screen.renderNode.frame = (0, 0, frame.w, frame.h)
            }
        }

        // 5. Cleanup: Restore child properties (to keep Node tree "pure" if needed,
        // though RenderNode is the source of truth now)
        for (i, restores) in allChildRestores.enumerated() {
            if i < node.children.count {
                let childNode = node.children[i]
                for (key, originalVal) in restores {
                    setFloatValue(node: childNode, key: key, value: originalVal)
                }
            }
        }

        // 6. Restore Self Properties
        for (key, originalVal) in selfRestores {
            setFloatValue(node: node, key: key, value: originalVal)
        }
        node.color = originalColor

        needsLayout = false
    }

    public func paint(
        offsetX: Float, offsetY: Float, clipFrame: (x: Float, y: Float, w: Float, h: Float)? = nil
    ) {
        guard let node = nodeData else { return }

        // Update absolute frame (include paint offsets)
        absFrame = (
            offsetX + frame.x + paintOffsetX, offsetY + frame.y + paintOffsetY, frame.w, frame.h
        )

        // 1. CULLING: Check if this node is visible within the clip frame
        if let clip = clipFrame {
            let ax = absFrame.x
            let ay = absFrame.y
            let nodeRight = ax + frame.w
            let nodeBottom = ay + frame.h
            let clipRight = clip.x + clip.w
            let clipBottom = clip.y + clip.h

            // Check for NO overlap
            if nodeRight < clip.x || ax > clipRight || nodeBottom < clip.y || ay > clipBottom {
                return  // Cull!
            }
        }

        // Delegate painting to the node (just self)
        node.frame = frame

        // Use animated color if available
        let originalColor = node.color
        if let animColor = animatedColor {
            node.color = animColor
        }

        // Use animated floats if available (some affect paint like cornerRadius)
        var selfRestores: [(String, Float)] = []
        for (key, val) in animatedFloats {
            let original = getFloatValue(node: node, key: key)
            selfRestores.append((key, original))
            setFloatValue(node: node, key: key, value: val)
        }

        // Draw self (include paint offsets)
        let ax = absFrame.x
        let ay = absFrame.y
        node.drawSelf(ax: ax, ay: ay)

        // Restore original properties
        node.color = originalColor
        for (key, originalVal) in selfRestores {
            setFloatValue(node: node, key: key, value: originalVal)
        }

        // Recursively paint children RenderNodes
        if node.layoutType == .scroll {
            impeller_save()
            impeller_clip_rect(ax, ay, frame.w, frame.h)

            // Current Scroll Viewport
            let viewport = (x: ax, y: ay, w: frame.w, h: frame.h)

            for child in children {
                // ScrollView children need offset subtraction
                child.paint(offsetX: ax, offsetY: ay - node.scrollOffset, clipFrame: viewport)
            }
            impeller_restore()
        } else {
            for child in children {
                child.paint(offsetX: ax, offsetY: ay, clipFrame: clipFrame)
            }
        }

        // Special Case: Navigator Painting
        // Paint the stack on top of local children (if any)
        if node.layoutType == .navigator, let nav = node.navigator {
            let ax = absFrame.x
            let ay = absFrame.y

            // Only paint top 2 for transitions, or all?
            // Application.swift painted last 2. Let's mimic that for perf + transitions.
            let stack = nav.stack
            let startIndex = max(0, stack.count - 2)

            for i in startIndex..<stack.count {
                stack[i].renderNode.paint(offsetX: ax, offsetY: ay, clipFrame: clipFrame)
            }
        }

        needsPaint = false
    }

    private func startColorAnimation(from: Color, to: Color, config: Animation) {
        if let id = colorAnimationId {
            AnimationController.shared.cancel(id: id)
        }

        colorAnimationId = AnimationController.shared.animate(
            from: from,
            to: to,
            animation: config
        ) { [weak self] value in
            self?.animatedColor = value
            self?.markNeedsPaint()
        }
    }

    private func startFloatAnimation(key: String, from: Float, to: Float, config: Animation) {
        if let id = floatAnimationIds[key] {
            AnimationController.shared.cancel(id: id)
        }

        floatAnimationIds[key] = AnimationController.shared.animate(
            from: from,
            to: to,
            animation: config
        ) { [weak self] value in
            self?.animatedFloats[key] = value
            self?.markNeedsLayout()  // Layout is safer as many floats affect layout
            self?.markNeedsPaint()
        }
    }

    // MARK: - Generic Property Accessors
    private func getFloatValue(node: Node, key: String) -> Float {
        switch key {
        case "minW": return node.minW
        case "minH": return node.minH
        case "marginLeft": return node.marginLeft
        case "marginTop": return node.marginTop
        case "marginRight": return node.marginRight
        case "marginBottom": return node.marginBottom
        case "cornerRadius": return node.cornerRadius
        case "borderWidth": return node.borderWidth
        case "padding": return node.padding
        case "fontSize": return node.fontSize
        default: return 0
        }
    }

    private func setFloatValue(node: Node, key: String, value: Float) {
        switch key {
        case "minW": node.minW = value
        case "minH": node.minH = value
        case "marginLeft": node.marginLeft = value
        case "marginTop": node.marginTop = value
        case "marginRight": node.marginRight = value
        case "marginBottom": node.marginBottom = value
        case "cornerRadius": node.cornerRadius = value
        case "borderWidth": node.borderWidth = value
        case "fontSize": node.fontSize = value
        case "padding": break
        default: break
        }
    }

    /// Hit test this node tree
    public func hitTest(x: Float, y: Float) -> RenderNode? {
        guard nodeData?.allowsHitTesting ?? true else { return nil }

        // Check children first (front to back)
        for child in children.reversed() {
            if let hit = child.hitTest(x: x, y: y) {
                return hit
            }
        }

        // Special Case: Navigator Hit Test (Front to Back)
        if nodeData?.layoutType == .navigator, let nav = nodeData?.navigator {
            if !nav.stack.isEmpty {
                // Hit test logic needs to be careful with coordinate spaces.
                // RenderNode hitTest usually takes absolute, and children check input x/y against their absFrame.
                // Navigator stack items are positioned relatively to this node.
                // But ScreenEntry.renderNode.paint() calculated its absFrame based on parent's absFrame.
                // So we can just forward the call.

                // Check stack top-down
                for screen in nav.stack.reversed() {
                    if let hit = screen.renderNode.hitTest(x: x, y: y) {
                        return hit
                    }
                }
            }
        }

        // Check self
        if x >= absFrame.x && x <= absFrame.x + absFrame.w && y >= absFrame.y
            && y <= absFrame.y + absFrame.h
        {
            return self
        }

        return nil
    }

    /// Get the underlying node (for event handling)
    public var node: Node? { nodeData }
}

// ==========================================
// GLOBAL COMPOSER INSTANCE
// ==========================================

/// The global composer for the application
public let composer = Composer()
