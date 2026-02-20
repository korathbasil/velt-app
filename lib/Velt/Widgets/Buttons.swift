import Foundation

// ==========================================
// BUTTON WIDGETS
// ==========================================

/// Standard Button - Defaults to Material 3 Filled Button style
/// Wraps FilledButton logic but maintains compatibility with legacy Button init where possible
public struct Button<Label: View>: View, BuiltinView {
    let label: Label
    let action: () -> Void
    let bgColor: Color
    let borderColor: Color
    let borderWidth: Float
    let cornerRadius: Float
    let pressedOpacity: Float
    let isEnabled: Bool

    // M3 Standard Init (Filled Button style)
    public init(
        bgColor: Color = .m3Primary,
        borderColor: Color = .clear,
        borderWidth: Float = 0,
        cornerRadius: Float = 20,  // M3 Pill
        pressedOpacity: Float = 0.8,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.bgColor = bgColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.pressedOpacity = pressedOpacity
        self.isEnabled = isEnabled
        self.action = action
        self.label = label()
    }

    // Convenience init for text strings
    public init(
        _ title: String,
        bgColor: Color = .m3Primary,
        textColor: Color = .m3OnPrimary,
        fontSize: Float = 16,  // M3 Default
        cornerRadius: Float = 20,  // M3 Pill
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) where Label == Text {
        self.bgColor = bgColor
        self.borderColor = .clear
        self.borderWidth = 0
        self.cornerRadius = cornerRadius
        self.pressedOpacity = 0.8
        self.isEnabled = isEnabled
        self.action = action
        self.label = Text(title, size: fontSize, color: textColor, weight: .medium)
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: bgColor)

        // Flexible Pill Layout
        node.paddingTop = 14
        node.paddingBottom = 14
        node.paddingLeading = 24
        node.paddingTrailing = 24

        node.cornerRadius = cornerRadius
        node.borderColor = borderColor
        node.borderWidth = borderWidth
        node.onClick = isEnabled ? action : nil
        node.layoutType = .zStack  // Overlay layout for ripple
        node.alignment = .center
        node.allowsHitTesting = isEnabled
        node.clipToBounds = true  // Clip ripple to rounded corners

        // Shadow for elevation (if filled and no border - heuristic)
        if borderWidth == 0 && bgColor.a > 0 {
            node.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level1.shadowAlpha)
            node.shadowBlur = Elevation.level1.shadowBlur
            node.shadowY = Elevation.level1.shadowOffset
        }

        if !isEnabled {
            node.opacity = 0.38
        }

        node.children = [label.makeNode()]

        // Ripple Effect - Scaled to avoid layout expansion
        node.onPress = { [weak node] in
            guard let node = node else { return }

            let rippleColor =
                self.bgColor.r > 0.8 && self.bgColor.g > 0.8 && self.bgColor.b > 0.8
                ? Color(r: 0, g: 0, b: 0, a: 0.1)
                : Color(r: 1, g: 1, b: 1, a: 0.25)

            let baseSize: Float = 10.0
            let targetSize = max(node.frame.w, node.frame.h) * 2.5
            let targetScale = targetSize / baseSize

            let ripple = Node(color: rippleColor)
            ripple.minW = baseSize
            ripple.minH = baseSize
            ripple.cornerRadius = baseSize / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.8
            ripple.scaleY = 0.8

            // ZStack alignment centers it automatically

            node.children.append(ripple)

            // Animate expand and fade
            let animation = Animation.easeOut(duration: 0.6)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = targetScale
            ripple.scaleY = targetScale
        }
        node.onRelease = { [weak node] in
            guard let node = node else { return }
            if let ripple = node.children.last {
                ripple.opacity = 0.0
            }
        }

        return node
    }
}

// Aliases/Specific Types

/// Filled Button - Alias to standard Button
public typealias FilledButton = Button

/// Outlined Button
public struct OutlinedButton<Label: View>: View, BuiltinView {
    let label: Label
    let action: () -> Void
    let borderColor: Color
    let textColor: Color
    let isEnabled: Bool

    public init(
        borderColor: Color = .m3Outline,
        textColor: Color = .m3Primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.borderColor = borderColor
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = label()
    }

    public init(
        _ title: String,
        borderColor: Color = .m3Outline,
        textColor: Color = .m3Primary,
        fontSize: Float = 16,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) where Label == Text {
        self.borderColor = borderColor
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = Text(title, size: fontSize, color: textColor, weight: .medium)
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        // Reuse Button logic via manual Node construction for specific outline ripple
        let node = Node(color: .clear)
        node.paddingTop = 14
        node.paddingBottom = 14
        node.paddingLeading = 24
        node.paddingTrailing = 24
        node.cornerRadius = 20
        node.borderColor = borderColor
        node.borderWidth = 1.5
        node.onClick = isEnabled ? action : nil
        node.layoutType = .zStack
        node.alignment = .center
        node.allowsHitTesting = isEnabled

        if !isEnabled { node.opacity = 0.38 }

        node.children = [label.makeNode()]

        // Ripple Effect - Scaled
        node.onPress = { [weak node] in
            guard let node = node else { return }
            let ripple = Node(color: Color(r: 0.38, g: 0.49, b: 0.98, a: 0.15))

            let baseSize: Float = 10.0
            let targetSize = max(node.frame.w, node.frame.h) * 2.5
            let targetScale = targetSize / baseSize

            ripple.minW = baseSize
            ripple.minH = baseSize
            ripple.cornerRadius = baseSize / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.8
            ripple.scaleY = 0.8

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.6)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = targetScale
            ripple.scaleY = targetScale
        }
        node.onRelease = { [weak node] in
            if let ripple = node?.children.last {
                ripple.opacity = 0.0
            }
        }
        return node
    }
}

/// Tonal Button
public struct TonalButton<Label: View>: View, BuiltinView {
    let label: Label
    let action: () -> Void
    let bgColor: Color
    let textColor: Color
    let isEnabled: Bool

    public init(
        bgColor: Color = .m3SecondaryContainer,
        textColor: Color = .m3OnSecondaryContainer,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.bgColor = bgColor
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = label()
    }

    public init(
        _ title: String,
        bgColor: Color = .m3SecondaryContainer,
        textColor: Color = .m3OnSecondaryContainer,
        fontSize: Float = 16,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) where Label == Text {
        self.bgColor = bgColor
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = Text(title, size: fontSize, color: textColor, weight: .medium)
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: bgColor)
        node.paddingTop = 14
        node.paddingBottom = 14
        node.paddingLeading = 24
        node.paddingTrailing = 24
        node.cornerRadius = 20
        node.onClick = isEnabled ? action : nil
        node.layoutType = .zStack
        node.alignment = .center
        node.allowsHitTesting = isEnabled
        node.clipToBounds = true

        if !isEnabled { node.opacity = 0.38 }

        node.children = [label.makeNode()]

        // Ripple
        node.onPress = { [weak node] in
            guard let node = node else { return }
            let ripple = Node(color: Color(r: 0.05, g: 0.11, b: 0.22, a: 0.15))

            let baseSize: Float = 10.0
            let targetSize = max(node.frame.w, node.frame.h) * 2.5
            let targetScale = targetSize / baseSize

            ripple.minW = baseSize
            ripple.minH = baseSize
            ripple.cornerRadius = baseSize / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.8
            ripple.scaleY = 0.8

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.6)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = targetScale
            ripple.scaleY = targetScale
        }
        node.onRelease = { [weak node] in
            if let ripple = node?.children.last {
                ripple.opacity = 0.0
            }
        }
        return node
    }
}

/// Text Button
public struct TextButton<Label: View>: View, BuiltinView {
    let label: Label
    let action: () -> Void
    let textColor: Color
    let isEnabled: Bool

    public init(
        textColor: Color = .m3Primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = label()
    }

    public init(
        _ title: String,
        textColor: Color = .m3Primary,
        fontSize: Float = 16,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) where Label == Text {
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = Text(title, size: fontSize, color: textColor, weight: .medium)
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        node.paddingTop = 14
        node.paddingBottom = 14
        node.paddingLeading = 24
        node.paddingTrailing = 24
        node.cornerRadius = 20
        node.onClick = isEnabled ? action : nil
        node.layoutType = .zStack
        node.alignment = .center
        node.allowsHitTesting = isEnabled
        node.clipToBounds = true

        if !isEnabled { node.opacity = 0.38 }

        node.children = [label.makeNode()]

        // Ripple
        node.onPress = { [weak node] in
            guard let node = node else { return }
            let ripple = Node(color: Color(r: 0.38, g: 0.49, b: 0.98, a: 0.12))

            let baseSize: Float = 10.0
            let targetSize = max(node.frame.w, node.frame.h) * 2.5
            let targetScale = targetSize / baseSize

            ripple.minW = baseSize
            ripple.minH = baseSize
            ripple.cornerRadius = baseSize / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.8
            ripple.scaleY = 0.8

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.6)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = targetScale
            ripple.scaleY = targetScale
        }
        node.onRelease = { [weak node] in
            if let ripple = node?.children.last {
                ripple.opacity = 0.0
            }
        }
        return node
    }
}

/// Elevated Button
public struct ElevatedButton<Label: View>: View, BuiltinView {
    let label: Label
    let action: () -> Void
    let bgColor: Color
    let textColor: Color
    let isEnabled: Bool

    public init(
        bgColor: Color = .m3Surface,
        textColor: Color = .m3Primary,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.bgColor = bgColor
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = label()
    }

    public init(
        _ title: String,
        bgColor: Color = .m3Surface,
        textColor: Color = .m3Primary,
        fontSize: Float = 16,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) where Label == Text {
        self.bgColor = bgColor
        self.textColor = textColor
        self.isEnabled = isEnabled
        self.action = action
        self.label = Text(title, size: fontSize, color: textColor, weight: .medium)
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: bgColor)
        node.paddingTop = 14
        node.paddingBottom = 14
        node.paddingLeading = 24
        node.paddingTrailing = 24
        node.cornerRadius = 20
        node.onClick = isEnabled ? action : nil
        node.layoutType = .zStack
        node.alignment = .center
        node.allowsHitTesting = isEnabled
        node.clipToBounds = true

        if isEnabled {
            node.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level1.shadowAlpha)
            node.shadowBlur = Elevation.level1.shadowBlur
            node.shadowY = Elevation.level1.shadowOffset
        } else {
            node.opacity = 0.38
        }

        node.children = [label.makeNode()]

        // Ripple & Elevation
        node.onPress = { [weak node] in
            guard let node = node else { return }
            node.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level2.shadowAlpha)
            node.shadowBlur = Elevation.level2.shadowBlur

            let ripple = Node(color: Color(r: 0.38, g: 0.49, b: 0.98, a: 0.15))

            let baseSize: Float = 10.0
            let targetSize = max(node.frame.w, node.frame.h) * 2.5
            let targetScale = targetSize / baseSize

            ripple.minW = baseSize
            ripple.minH = baseSize
            ripple.cornerRadius = baseSize / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.8
            ripple.scaleY = 0.8

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.6)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = targetScale
            ripple.scaleY = targetScale
        }
        node.onRelease = { [weak node] in
            if self.isEnabled {
                node?.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level1.shadowAlpha)
                node?.shadowBlur = Elevation.level1.shadowBlur
            }
            if let ripple = node?.children.last {
                ripple.opacity = 0.0
            }
        }
        return node
    }
}

// ==========================================
// FAB
// ==========================================

/// Floating Action Button
public struct FAB<Label: View>: View, BuiltinView {
    let label: Label
    let action: () -> Void
    let bgColor: Color
    let textColor: Color
    let size: FABSize

    public enum FABSize {
        case small
        case regular
        case large

        var dimension: Float {
            switch self {
            case .small: return 40
            case .regular: return 56
            case .large: return 96
            }
        }
        var iconSize: Float {
            switch self {
            case .small: return 20
            case .regular: return 24
            case .large: return 36
            }
        }
    }

    public init(
        bgColor: Color = .m3PrimaryContainer,
        textColor: Color = .m3OnPrimaryContainer,
        size: FABSize = .regular,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.bgColor = bgColor
        self.textColor = textColor
        self.size = size
        self.action = action
        self.label = label()
    }

    public init(
        _ icon: String,
        bgColor: Color = .m3PrimaryContainer,
        textColor: Color = .m3OnPrimaryContainer,
        size: FABSize = .regular,
        action: @escaping () -> Void
    ) where Label == Text {
        self.bgColor = bgColor
        self.textColor = textColor
        self.size = size
        self.action = action
        self.label = Text(icon, size: size.iconSize, color: textColor, weight: .medium)
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: bgColor)
        node.minW = size.dimension
        node.minH = size.dimension
        node.cornerRadius = size.dimension / 2
        node.onClick = action
        node.layoutType = .zStack
        node.alignment = .center
        node.clipToBounds = true

        // Initial Elevation
        node.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level3.shadowAlpha)
        node.shadowBlur = Elevation.level3.shadowBlur
        node.shadowY = Elevation.level3.shadowOffset

        node.children = [label.makeNode()]

        let animation = Animation.easeOut(duration: 0.15)
        node.animationConfig = animation

        // Ripple & Elevate
        node.onPress = { [weak node] in
            guard let node = node else { return }
            node.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level4.shadowAlpha)
            node.shadowBlur = Elevation.level4.shadowBlur

            let ripple = Node(color: Color(r: 0.0, g: 0.08, b: 0.35, a: 0.2))

            let baseSize: Float = 10.0
            let targetSize = self.size.dimension * 2.5
            let targetScale = targetSize / baseSize

            ripple.minW = baseSize
            ripple.minH = baseSize
            ripple.cornerRadius = baseSize / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.8
            ripple.scaleY = 0.8

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.5)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = targetScale
            ripple.scaleY = targetScale
        }
        node.onRelease = { [weak node] in
            node?.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level3.shadowAlpha)
            node?.shadowBlur = Elevation.level3.shadowBlur
            if let ripple = node?.children.last {
                ripple.opacity = 0.0
            }
        }
        return node
    }
}

public struct ExtendedFAB: View, BuiltinView {
    let icon: String
    let label: String
    let action: () -> Void
    let bgColor: Color
    let textColor: Color

    public init(
        icon: String,
        label: String,
        bgColor: Color = .m3PrimaryContainer,
        textColor: Color = .m3OnPrimaryContainer,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.bgColor = bgColor
        self.textColor = textColor
        self.action = action
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        // Root node for layout (ZStack for ripple) + Elevation + Action
        let node = Node(color: bgColor)
        node.padding = 16
        node.paddingLeading = 16
        node.paddingTrailing = 20
        node.cornerRadius = 16
        node.onClick = action
        node.layoutType = .zStack
        node.alignment = .center

        // Elevation
        node.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level3.shadowAlpha)
        node.shadowBlur = Elevation.level3.shadowBlur
        node.shadowY = Elevation.level3.shadowOffset

        // Content Container (HStack)
        let content = Node(color: .clear)
        content.layoutType = .hStack
        content.alignment = .center

        let iconNode = Node(color: .clear)
        iconNode.text = icon
        iconNode.textColor = textColor
        iconNode.fontSize = 24

        let labelNode = Node(color: .clear)
        labelNode.text = label
        labelNode.textColor = textColor
        labelNode.fontSize = 16
        labelNode.marginLeft = 12

        content.children = [iconNode, labelNode]
        node.children = [content]
        node.clipToBounds = true

        // Ripple & Elevate
        node.onPress = { [weak node] in
            guard let node = node else { return }
            node.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level4.shadowAlpha)

            let ripple = Node(color: Color(r: 0.0, g: 0.08, b: 0.35, a: 0.2))
            let baseSize: Float = 10.0
            let targetSize = max(node.frame.w, node.frame.h) * 2.5
            let targetScale = targetSize / baseSize

            ripple.minW = baseSize
            ripple.minH = baseSize
            ripple.cornerRadius = baseSize / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.8
            ripple.scaleY = 0.8

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.5)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = targetScale
            ripple.scaleY = targetScale
        }
        node.onRelease = { [weak node] in
            node?.shadowColor = Color(r: 0, g: 0, b: 0, a: Elevation.level3.shadowAlpha)
            if let ripple = node?.children.last, ripple.color.a == 0.2 {
                // Remove specific ripple if needed, or rely on RippleEffect cleanup
                // RippleEffect helper handles cleanup mostly?
                // Actually RippleEffect helper in previous impl didn't handle release cleanup automatically for separate views without state
                // But my inline logic in Buttons.swift managed it manually.
                // Here I'm using RippleEffect.addRipple. Does it handle removal?
                // Let's check RippleEffect.swift?
                // I'll stick to the manual implementation style I had but using ZStack correctly.
                if let ripple = node?.children.last {
                    ripple.opacity = 0.0
                }
            }
        }
        return node
    }
}

// ==========================================
// PRESSABLE
// ==========================================

/// Pressable - A generic touchable wrapper
public struct Pressable<Content: View>: View, BuiltinView {
    let content: Content
    let onTap: (() -> Void)?
    let onPress: (() -> Void)?
    let onRelease: (() -> Void)?
    let onLongPress: (() -> Void)?
    let pressedOpacity: Float
    let hitTestingEnabled: Bool

    public init(
        onTap: (() -> Void)? = nil,
        onPress: (() -> Void)? = nil,
        onRelease: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        pressedOpacity: Float = 0.7,
        hitTestingEnabled: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.onTap = onTap
        self.onPress = onPress
        self.onRelease = onRelease
        self.onLongPress = onLongPress
        self.pressedOpacity = pressedOpacity
        self.hitTestingEnabled = hitTestingEnabled
        self.content = content()
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let childNode = content.makeNode()
        childNode.onClick = onTap
        childNode.onLongPress = onLongPress
        childNode.allowsHitTesting = hitTestingEnabled

        if onPress != nil || pressedOpacity < 1.0 {
            let normalOpacity = childNode.opacity
            childNode.onPress = { [weak childNode] in
                childNode?.opacity = self.pressedOpacity
                self.onPress?()
            }
            childNode.onRelease = { [weak childNode] in
                childNode?.opacity = normalOpacity
                self.onRelease?()
            }
        }
        return childNode
    }
}

public typealias GestureDetector = Pressable
public typealias InkWell = Pressable
