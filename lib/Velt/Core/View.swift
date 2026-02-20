import Foundation
import ImpellerBackend

// ==========================================
// 1. PRIMITIVES
// ==========================================

public enum LayoutType { case vStack, hStack, zStack, grid, group, leaf, scroll, navigator }
public typealias Alignment = Alignment2D
public enum ShapeType { case rectangle, circle }
public enum InputEvent {
    case char(Character)
    case backspace
}

// ==========================================
// 2. THE NODE ENGINE
// ==========================================

public class Node {
    var frame: (x: Float, y: Float, w: Float, h: Float) = (0, 0, 0, 0)
    var absFrame: (x: Float, y: Float, w: Float, h: Float) = (0, 0, 0, 0)
    var minW: Float = 0
    var minH: Float = 0
    var isSpacer: Bool = false
    var padding: Float = 0
    var color: Color
    var alignment: Alignment = .center
    var mainAxisAlignment: MainAxisAlignment = .start
    var crossAxisAlignment: CrossAxisAlignment = .center
    var shapeType: ShapeType = .rectangle
    var cornerRadius: Float = 0
    var borderWidth: Float = 0
    var borderColor: Color = .clear

    // ... (rest of properties same)

    public var marginLeft: Float = 0
    public var marginTop: Float = 0
    public var marginRight: Float = 0
    public var marginBottom: Float = 0

    // Shadow properties
    var shadowColor: Color = .clear
    var shadowBlur: Float = 0
    var shadowX: Float = 0
    var shadowY: Float = 0

    // Opacity & Visibility
    public var opacity: Float = 1.0
    public var isHidden: Bool = false
    public var allowsHitTesting: Bool = true
    public var clipToBounds: Bool = false

    // Transform properties
    public var rotation: Float = 0  // degrees
    public var scaleX: Float = 1.0
    public var scaleY: Float = 1.0
    public var anchorX: Float = 0.5  // 0-1, center by default
    public var anchorY: Float = 0.5

    // Layout constraints
    public var maxW: Float? = nil
    public var maxH: Float? = nil
    public var aspectRatio: Float? = nil
    public var zIndex: Int = 0

    // Per-edge padding (enhanced)

    // Per-edge padding (enhanced)
    public var paddingTop: Float = 0
    public var paddingLeading: Float = 0
    public var paddingBottom: Float = 0
    public var paddingTrailing: Float = 0

    // Effects (TODO: Requires C++ backend support)
    public var blur: Float = 0
    public var grayscale: Float = 0  // 0-1
    public var brightness: Float = 0  // -1 to 1
    public var contrast: Float = 1.0  // multiplier
    public var saturation: Float = 1.0

    // Interaction
    public var onClick: (() -> Void)?
    public var onPress: (() -> Void)?
    public var onRelease: (() -> Void)?
    public var onAppear: (() -> Void)?
    public var onLongPress: (() -> Void)?

    // Keyboard Input
    public var onInput: ((InputEvent) -> Void)?

    var children: [Node] = []
    var layoutType: LayoutType = .vStack
    var gridColumns: Int = 2
    var text: String?
    var fontSize: Float = 20
    var fontFamily: String = "Sans"
    public var textColor: Color = .black
    public var textureId: Int?
    public var imagePath: String?

    // Scroll Support
    public var scrollOffset: Float = 0
    public var scrollAxis: Axis = .vertical
    public var onScroll: ((Float, Float) -> Void)?

    // Nested Navigation Support
    public var navigator: Navigator?

    // Animation support
    public var animationConfig: Animation?
    var previousColor: Color?
    var colorAnimationId: UUID?

    public init(color: Color) { self.color = color }

    public func layout(maxWidth: Float, maxHeight: Float) -> (w: Float, h: Float) {
        var maxWidth = maxWidth
        if let maxW = maxW { maxWidth = min(maxWidth, maxW) }
        var maxHeight = maxHeight
        if let maxH = maxH { maxHeight = min(maxHeight, maxH) }

        if let textContent = text {
            let size = impeller_measure_text(textContent, fontSize, fontFamily)
            minW = max(minW, size.width)
            minH = max(minH, size.height)
        }
        // If image, we could measure it too, but for now we rely on explicit width/height
        // or texture dimensions (requires loading first which is async/expensive)
        // For simple impl, we assume user provides W/H for images.

        let horizontalPadding = paddingLeading + paddingTrailing + (padding * 2)
        let verticalPadding = paddingTop + paddingBottom + (padding * 2)

        let availableW = maxWidth - horizontalPadding
        let availableH = maxHeight - verticalPadding

        if layoutType == .grid { return layoutGrid(availableW: availableW, availableH: availableH) }

        // 1. Recursive Layout for Children (first pass)
        var usedSpace: Float = 0
        var maxCrossDim: Float = 0
        var visibleChildren_count = 0
        for child in children { if !child.isSpacer { visibleChildren_count += 1 } }

        if layoutType != .leaf {
            for child in children where !child.isSpacer {
                var childMaxH = availableH
                var childMaxW = availableW

                // ScrollView infinite constraints
                if layoutType == .scroll {
                    if scrollAxis == .vertical { childMaxH = 10000 }
                    if scrollAxis == .horizontal { childMaxW = 10000 }
                }

                // CrossAxis Stretch Logic (Pre-layout constraint)
                // If stretching, we force the child to fill the cross axis?
                // Actually `layout(maxW, maxH)` only caps it.
                // We will stretch the final frame later.

                let size = child.layout(maxWidth: childMaxW, maxHeight: childMaxH)
                child.frame = (0, 0, size.w, size.h)

                // Accumulate size including margins
                if layoutType == .vStack {
                    usedSpace += size.h + child.marginTop + child.marginBottom
                    maxCrossDim = max(maxCrossDim, size.w + child.marginLeft + child.marginRight)
                } else if layoutType == .hStack {
                    usedSpace += size.w + child.marginLeft + child.marginRight
                    maxCrossDim = max(maxCrossDim, size.h + child.marginTop + child.marginBottom)
                } else {
                    maxCrossDim = max(maxCrossDim, size.w + child.marginLeft + child.marginRight)
                    usedSpace = max(usedSpace, size.h + child.marginTop + child.marginBottom)
                }
            }
        }

        // 2. Calculate Final Dimensions (Sizing)
        // Rule: If MainAxis defaults (.start) -> Shrink to content.
        //       If MainAxis distributes (center/end/space) -> Fill available space.
        //       Exception: ScrollView always fills available.
        //       Exception: ZStack/Group shrinks to content.

        // Note: Existing code had some hardcoded "fill" logic for stacks.
        // We will make it smart based on alignment.

        let finalW: Float
        let finalH: Float

        if layoutType == .leaf {
            finalW = minW
            finalH = minH
        } else if layoutType == .scroll {
            finalW = maxWidth
            finalH = maxHeight
        } else if layoutType == .zStack || layoutType == .group {
            finalW = max(minW, maxCrossDim + horizontalPadding)
            finalH = max(minH, usedSpace + verticalPadding)
        } else if layoutType == .vStack {
            // Width: Cross axis.
            finalW =
                (crossAxisAlignment == .stretch)
                ? maxWidth : max(minW, maxCrossDim + horizontalPadding)

            // Height: Main axis.
            if mainAxisAlignment == .start {
                finalH = max(minH, usedSpace + verticalPadding)  // Shrink
            } else {
                finalH = max(minH, maxHeight)  // Fill to distribute
            }
        } else if layoutType == .hStack {
            // Width: Main axis.
            if mainAxisAlignment == .start {
                finalW = max(minW, usedSpace + horizontalPadding)  // Shrink
            } else {
                finalW = max(minW, maxWidth)  // Fill
            }
            // Height: Cross axis.
            finalH =
                (crossAxisAlignment == .stretch)
                ? maxHeight : max(minH, maxCrossDim + verticalPadding)
        } else {
            finalW = maxWidth
            finalH = maxHeight
        }

        // 3. Distribution Logic (Main Axis)
        var startOffset: Float = padding
        var gap: Float = 0

        if layoutType == .vStack {
            let available = finalH - padding * 2
            let remaining = max(0, available - usedSpace)
            // Note: usedSpace includes margins. explicit spacing (via margins) is preserved.

            switch mainAxisAlignment {
            case .start:
                gap = 0
                startOffset = padding
            case .center:
                startOffset = padding + remaining / 2
            case .end:
                startOffset = padding + remaining
            case .spaceBetween:
                gap = visibleChildren_count > 1 ? remaining / Float(visibleChildren_count - 1) : 0
            case .spaceAround:
                gap = visibleChildren_count > 0 ? remaining / Float(visibleChildren_count) : 0
                startOffset = padding + gap / 2
            case .spaceEvenly:
                gap = visibleChildren_count > 0 ? remaining / Float(visibleChildren_count + 1) : 0
                startOffset = padding + gap
            }
        } else if layoutType == .hStack {
            let available = finalW - padding * 2
            let remaining = max(0, available - usedSpace)
            switch mainAxisAlignment {
            case .start:
                gap = 0
                startOffset = padding
            case .center:
                startOffset = padding + remaining / 2
            case .end:
                startOffset = padding + remaining
            case .spaceBetween:
                gap = visibleChildren_count > 1 ? remaining / Float(visibleChildren_count - 1) : 0
            case .spaceAround:
                gap = visibleChildren_count > 0 ? remaining / Float(visibleChildren_count) : 0
                startOffset = padding + gap / 2
            case .spaceEvenly:
                gap = visibleChildren_count > 0 ? remaining / Float(visibleChildren_count + 1) : 0
                startOffset = padding + gap
            }
        }

        // 4. Positioning Loop
        var cursorX = (layoutType == .hStack) ? startOffset : (padding + paddingLeading)
        var cursorY = (layoutType == .vStack) ? startOffset : (padding + paddingTop)

        for child in children {
            if child.isSpacer { continue }  // Spacers handled via flex/gap? Actually spacers break this logic.
            // If explicit spacers exist, should we ignore alignment?
            // Usually usage of Spacer() overrides alignment.
            // For now, assuming Spacer() is just a flexible child?
            // Actually, if legacy Spacer() is used, it might fight with this logic.
            // Let's assume user uses EITHER Spacer() OR mainAxisAlignment.

            let w = child.frame.w
            let h = child.frame.h

            // Apply Cross Alignment
            var x = cursorX
            var y = cursorY

            if layoutType == .vStack {
                // Cross Axis: Horizontal
                if crossAxisAlignment == .center {
                    x = padding + (finalW - padding * 2 - w) / 2
                } else if crossAxisAlignment == .end {
                    x = finalW - padding - w
                } else if crossAxisAlignment == .stretch {
                    x = padding
                    child.frame = (x, 0, finalW - padding * 2, h)  // Force width
                } else {  // Start
                    x = padding + paddingLeading
                }

                child.frame = (x + child.marginLeft, cursorY + child.marginTop, child.frame.w, h)
                cursorY += h + child.marginTop + child.marginBottom + gap

            } else if layoutType == .hStack {
                // Cross Axis: Vertical
                if crossAxisAlignment == .center {
                    y = padding + (finalH - padding * 2 - h) / 2
                } else if crossAxisAlignment == .end {
                    y = finalH - padding - h
                } else if crossAxisAlignment == .stretch {
                    y = padding
                    child.frame = (0, y, w, finalH - padding * 2)  // Force height
                } else {  // Start
                    y = padding + paddingTop
                }

                child.frame = (cursorX + child.marginLeft, y + child.marginTop, w, child.frame.h)
                cursorX += w + child.marginLeft + child.marginRight + gap

            } else if layoutType == .zStack || layoutType == .group {
                // ZStack Alignment (using Alignment2D)
                var cX: Float = padding + paddingLeading
                var cY: Float = padding + paddingTop
                if alignment.horizontal == .center {
                    cX = padding + paddingLeading + (availableW - w) / 2
                } else if alignment.horizontal == .trailing {
                    cX = finalW - padding - paddingTrailing - w
                }
                if alignment.vertical == .center {
                    cY = padding + paddingTop + (availableH - h) / 2
                } else if alignment.vertical == .bottom {
                    cY = finalH - padding - paddingBottom - h
                }
                child.frame = (cX + child.marginLeft, cY + child.marginTop, w, h)
            } else {
                // ScrollView / Other
                child.frame = (0, 0, w, h)
            }
        }

        return (finalW, finalH)
    }

    func layoutGrid(availableW: Float, availableH: Float) -> (w: Float, h: Float) {
        let colWidth = availableW / Float(gridColumns)
        var cursorX = padding
        var cursorY = padding
        var maxRowH: Float = 0
        var currentCol = 0
        for child in children {
            let size = child.layout(maxWidth: colWidth, maxHeight: availableH)
            child.frame = (cursorX, cursorY, size.w, size.h)
            maxRowH = max(maxRowH, size.h)
            currentCol += 1
            cursorX += colWidth
            if currentCol >= gridColumns {
                currentCol = 0
                cursorX = padding
                cursorY += maxRowH + 10
                maxRowH = 0
            }
        }
        return (availableW + padding * 2, cursorY + maxRowH + padding)
    }

    public func render(
        offsetX: Float, offsetY: Float, clipFrame: (x: Float, y: Float, w: Float, h: Float)? = nil
    ) {
        let ax = offsetX + frame.x
        let ay = offsetY + frame.y

        // 1. CULLING: Check if this node is visible within the clip frame
        if let clip = clipFrame {
            let nodeRight = ax + frame.w
            let nodeBottom = ay + frame.h
            let clipRight = clip.x + clip.w
            let clipBottom = clip.y + clip.h

            // Check for NO overlap (Standard AABB, strict)
            if nodeRight < clip.x || ax > clipRight || nodeBottom < clip.y || ay > clipBottom {
                return  // Cull!
            }
        }

        drawSelf(ax: ax, ay: ay)

        if layoutType == .scroll {
            impeller_save()
            impeller_clip_rect(ax, ay, frame.w, frame.h)

            // Current Scroll Viewport in absolute coordinates
            let viewport = (x: ax, y: ay, w: frame.w, h: frame.h)

            // Render children shifted by scrollOffset with NEW CLIP
            children.forEach {
                $0.render(offsetX: ax, offsetY: ay - scrollOffset, clipFrame: viewport)
            }
            impeller_restore()
        } else {
            // Pass down the existing clipFrame (or nil) to children
            children.forEach { $0.render(offsetX: ax, offsetY: ay, clipFrame: clipFrame) }
        }
    }

    /// Internal method to draw just this node (no recursion)
    public func drawSelf(ax: Float, ay: Float) {
        absFrame = (ax, ay, frame.w, frame.h)
        if shadowColor.a > 0 {
            if cornerRadius > 0 {
                impeller_draw_rounded_rect_with_shadow(
                    ax, ay, frame.w, frame.h,
                    color.r, color.g, color.b, color.a,
                    cornerRadius,
                    shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a,
                    shadowBlur, shadowX, shadowY
                )
            } else {
                impeller_draw_rect_with_shadow(
                    ax, ay, frame.w, frame.h,
                    color.r, color.g, color.b, color.a,
                    shadowColor.r, shadowColor.g, shadowColor.b, shadowColor.a,
                    shadowBlur, shadowX, shadowY
                )
            }
        } else if color.a > 0 {
            if cornerRadius > 0 {
                impeller_draw_rounded_rect(
                    ax, ay, frame.w, frame.h, color.r, color.g, color.b, color.a, cornerRadius)
            } else {
                impeller_draw_rect(ax, ay, frame.w, frame.h, color.r, color.g, color.b, color.a)
            }
        }
        if let path = imagePath {
            // Cache texture ID to avoid reloading every frame
            if textureId == nil {
                textureId = Int(impeller_load_texture(path))
            }
            if let tid = textureId, tid > 0 {
                impeller_draw_texture(Int32(tid), ax, ay, frame.w, frame.h)
            }
        } else if let tid = textureId {
            impeller_draw_texture(Int32(tid), ax, ay, frame.w, frame.h)
        }
        if let t = text {
            impeller_draw_text(
                t, ax, ay, fontSize, textColor.r, textColor.g, textColor.b, textColor.a, fontFamily)
        }
    }

    func shadow(
        color: Color = Color(r: 0, g: 0, b: 0, a: 0.5), blur: Float = 10, x: Float = 5, y: Float = 5
    ) -> Node {
        self.shadowColor = color
        self.shadowBlur = blur
        self.shadowX = x
        self.shadowY = y
        return self
    }

    @discardableResult
    public func size(_ w: Float, _ h: Float) -> Node {
        self.minW = w
        self.minH = h
        return self
    }

    public func hitTest(x: Float, y: Float) -> Node? {
        for child in children.reversed() { if let hit = child.hitTest(x: x, y: y) { return hit } }
        let c =
            x >= absFrame.x && x <= absFrame.x + absFrame.w && y >= absFrame.y
            && y <= absFrame.y + absFrame.h
        return (c && onClick != nil) ? self : nil
    }
}

// ==========================================
// 3. THE VIEW PROTOCOL
// ==========================================

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

protocol BuiltinView {
    func makeNode() -> Node
}

extension View {
    func makeNode() -> Node {
        if let builtin = self as? BuiltinView {
            return builtin.makeNode()
        }
        return body.makeNode()
    }

    // MARK: - Shadow
    public func shadow(
        color: Color = Color(r: 0, g: 0, b: 0, a: 0.5), blur: Float = 10, x: Float = 5, y: Float = 5
    ) -> some View {
        VeltModifierView(content: self) { node in
            _ = node.shadow(color: color, blur: blur, x: x, y: y)
        }
    }

    // MARK: - Padding (Multiple Overloads)
    public func padding(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.padding = value
            node.paddingTop = value
            node.paddingLeading = value
            node.paddingBottom = value
            node.paddingTrailing = value
        }
    }

    public func padding(_ edges: EdgeSet, _ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            if edges.contains(.top) { node.paddingTop = value }
            if edges.contains(.leading) { node.paddingLeading = value }
            if edges.contains(.bottom) { node.paddingBottom = value }
            if edges.contains(.trailing) { node.paddingTrailing = value }
        }
    }

    public func padding(top: Float = 0, leading: Float = 0, bottom: Float = 0, trailing: Float = 0)
        -> some View
    {
        VeltModifierView(content: self) { node in
            node.paddingTop = top
            node.paddingLeading = leading
            node.paddingBottom = bottom
            node.paddingTrailing = trailing
        }
    }

    public func padding(horizontal: Float = 0, vertical: Float = 0) -> some View {
        VeltModifierView(content: self) { node in
            node.paddingLeading = horizontal
            node.paddingTrailing = horizontal
            node.paddingTop = vertical
            node.paddingBottom = vertical
        }
    }

    // MARK: - Background & Foreground
    public func background(_ color: Color) -> some View {
        VeltModifierView(content: self) { node in
            node.color = color
        }
    }

    public func foregroundColor(_ color: Color) -> some View {
        VeltModifierView(content: self) { node in
            node.textColor = color
        }
    }

    public func tint(_ color: Color) -> some View {
        foregroundColor(color)
    }

    // MARK: - Frame (Enhanced)
    public func frame(w: Float? = nil, h: Float? = nil) -> some View {
        VeltModifierView(content: self) { node in
            if let w = w {
                node.minW = w
                node.frame.w = w
            }
            if let h = h {
                node.minH = h
                node.frame.h = h
            }
        }
    }

    public func frame(
        minWidth: Float? = nil, idealWidth: Float? = nil, maxWidth: Float? = nil,
        minHeight: Float? = nil, idealHeight: Float? = nil, maxHeight: Float? = nil
    ) -> some View {
        VeltModifierView(content: self) { node in
            if let minW = minWidth { node.minW = minW }
            if let idealW = idealWidth {
                node.minW = idealW
                node.frame.w = idealW
            }
            if let maxW = maxWidth { node.maxW = maxW }
            if let minH = minHeight { node.minH = minH }
            if let idealH = idealHeight {
                node.minH = idealH
                node.frame.h = idealH
            }
            if let maxH = maxHeight { node.maxH = maxH }
        }
    }

    // MARK: - Corner Radius & Border
    public func cornerRadius(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.cornerRadius = value
        }
    }

    public func border(_ color: Color, width: Float = 1) -> some View {
        VeltModifierView(content: self) { node in
            node.borderColor = color
            node.borderWidth = width
        }
    }

    public func clipped() -> some View {
        VeltModifierView(content: self) { node in
            node.clipToBounds = true
        }
    }

    // MARK: - Margin (For Layout Spacing)
    public func marginLeft(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.marginLeft = value
        }
    }

    public func marginTop(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.marginTop = value
        }
    }

    public func marginRight(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.marginRight = value
        }
    }

    public func marginBottom(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.marginBottom = value
        }
    }

    public func margin(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.marginLeft = value
            node.marginTop = value
            node.marginRight = value
            node.marginBottom = value
        }
    }

    public func margin(_ key: EdgeSet, _ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            if key.contains(.top) { node.marginTop = value }
            if key.contains(.leading) { node.marginLeft = value }
            if key.contains(.bottom) { node.marginBottom = value }
            if key.contains(.trailing) { node.marginRight = value }
        }
    }

    public func margin(horizontal: Float = 0, vertical: Float = 0) -> some View {
        return VeltModifierView(content: self) { node in
            node.marginLeft = horizontal
            node.marginRight = horizontal
            node.marginTop = vertical
            node.marginBottom = vertical
        }
    }

    // MARK: - Opacity & Visibility
    public func opacity(_ value: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.opacity = value
        }
    }

    public func hidden() -> some View {
        VeltModifierView(content: self) { node in
            node.isHidden = true
        }
    }

    public func visible(_ condition: Bool) -> some View {
        VeltModifierView(content: self) { node in
            node.isHidden = !condition
        }
    }

    public func disabled(_ isDisabled: Bool) -> some View {
        VeltModifierView(content: self) { node in
            node.allowsHitTesting = !isDisabled
            if isDisabled { node.opacity = 0.5 }
        }
    }

    public func allowsHitTesting(_ enabled: Bool) -> some View {
        VeltModifierView(content: self) { node in
            node.allowsHitTesting = enabled
        }
    }

    // MARK: - Transforms
    public func rotationEffect(_ degrees: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.rotation = degrees
        }
    }

    public func scaleEffect(_ scale: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.scaleX = scale
            node.scaleY = scale
        }
    }

    public func scaleEffect(x: Float = 1, y: Float = 1) -> some View {
        VeltModifierView(content: self) { node in
            node.scaleX = x
            node.scaleY = y
        }
    }

    public func offset(x: Float = 0, y: Float = 0) -> some View {
        VeltModifierView(content: self) { node in
            node.marginLeft += x
            node.marginTop += y
        }
    }

    // MARK: - Effects (TODO: Requires C++ backend)
    public func blur(_ radius: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.blur = radius
        }
    }

    public func grayscale(_ amount: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.grayscale = amount
        }
    }

    public func brightness(_ amount: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.brightness = amount
        }
    }

    public func contrast(_ amount: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.contrast = amount
        }
    }

    public func saturation(_ amount: Float) -> some View {
        VeltModifierView(content: self) { node in
            node.saturation = amount
        }
    }

    // MARK: - Z-Index
    public func zIndex(_ value: Int) -> some View {
        VeltModifierView(content: self) { node in
            node.zIndex = value
        }
    }

    // MARK: - Aspect Ratio
    public func aspectRatio(_ ratio: Float?, contentMode: ContentMode = .fit) -> some View {
        VeltModifierView(content: self) { node in
            node.aspectRatio = ratio
        }
    }

    // MARK: - Gestures
    public func onTapGesture(perform action: @escaping () -> Void) -> some View {
        VeltModifierView(content: self) { node in
            node.onClick = action
        }
    }

    public func onLongPressGesture(perform action: @escaping () -> Void) -> some View {
        VeltModifierView(content: self) { node in
            node.onLongPress = action
        }
    }

    // MARK: - Lifecycle
    public func onAppear(perform action: @escaping () -> Void) -> some View {
        VeltModifierView(content: self) { node in
            node.onAppear = action
        }
    }

    // MARK: - Navigation
    public func navigationDestination<D: Hashable, V: View>(
        for type: D.Type, @ViewBuilder destination: @escaping (D) -> V
    ) -> some View {
        NavigationRegistry.shared.builders[ObjectIdentifier(type)] = { val in
            AnyView(destination(val as! D))
        }
        return self
    }
}

// === FIX: Group is now a transparent Renderable Node ===
// === INTERNAL FRAGMENT (Hidden from Public API) ===
// Replaces public "Group" to avoid user confusion
public struct _Fragment: View, BuiltinView {
    var children: [AnyView]

    // If instantiated directly by internal logic
    init(children: [AnyView]) {
        self.children = children
    }

    // Convenience init for ViewBuilder usage
    init(@ViewBuilder content: () -> _Fragment) {
        let group = content()
        self.children = group.children
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)  // Transparent container
        node.layoutType = .group
        node.children = children.map { $0.makeNode() }
        return node
    }
}

// ==========================================
// 4. RESULT BUILDER
// ==========================================

@resultBuilder
public struct ViewBuilder {
    public static func buildBlock() -> _Fragment { _Fragment(children: []) }

    // Variadic View Builder (Infinite Children)
    public static func buildBlock<each Content: View>(_ content: repeat each Content) -> _Fragment {
        var views: [AnyView] = []
        repeat views.append(AnyView(each content))
        return _Fragment(children: views)
    }

    // Fallback for "If/Else" (ConditionalContent)
    public static func buildIf(_ content: _Fragment?) -> _Fragment {
        content ?? _Fragment(children: [])
    }

    public static func buildEither(first: _Fragment) -> _Fragment { first }
    public static func buildEither(second: _Fragment) -> _Fragment { second }
}

// Helper for modifiers
struct VeltModifierView<Content: View>: View, BuiltinView {
    let content: Content
    let modifier: (Node) -> Void

    init(content: Content, modifier: @escaping (Node) -> Void) {
        self.content = content
        self.modifier = modifier
    }

    var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = content.makeNode()
        modifier(node)
        return node
    }
}
