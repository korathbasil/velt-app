import Foundation

// ==========================================
// CHIP WIDGETS
// ==========================================

/// Base Chip component - Pill shaped with radius 100
public struct Chip<Label: View>: View, BuiltinView {
    let label: Label
    let action: (() -> Void)?
    let bgColor: Color
    let textColor: Color
    let isSelected: Bool

    public init(
        bgColor: Color = .m3SurfaceVariant,
        textColor: Color = .m3OnSurfaceVariant,
        isSelected: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.bgColor = bgColor
        self.textColor = textColor
        self.isSelected = isSelected
        self.action = action
        self.label = label()
    }

    public init(
        _ title: String,
        bgColor: Color = .m3SurfaceVariant,
        textColor: Color = .m3OnSurfaceVariant,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) where Label == Text {
        self.bgColor = bgColor
        self.textColor = textColor
        self.isSelected = isSelected
        self.action = action
        self.label = Text(title, size: 14, color: textColor, weight: .medium)
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let finalBg = isSelected ? Color.m3SecondaryContainer : bgColor
        let node = Node(color: finalBg)
        // Pill shape adjustments for optimal internal spacing
        node.paddingTop = 8
        node.paddingBottom = 8
        node.paddingLeading = 16
        node.paddingTrailing = 16
        node.cornerRadius = 100  // Fully rounded pill
        node.onClick = action
        node.layoutType = .zStack
        node.alignment = .center

        if isSelected {
            node.shadowColor = Color(r: 0, g: 0, b: 0, a: 0.05)
            node.shadowBlur = 4
        }

        node.children = [label.makeNode()]

        // Ripple Animation
        node.onPress = { [weak node] in
            guard let node = node else { return }
            let ripple = Node(color: Color(r: 0.05, g: 0.11, b: 0.22, a: 0.2))
            let size = max(node.frame.w, node.frame.h) * 2.5
            ripple.minW = size
            ripple.minH = size
            ripple.cornerRadius = size / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.0
            ripple.scaleY = 0.0
            ripple.marginLeft = (node.frame.w - size) / 2
            ripple.marginTop = (node.frame.h - size) / 2

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.5)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = 1.0
            ripple.scaleY = 1.0
        }
        node.onRelease = { [weak node] in
            if let ripple = node?.children.last {
                ripple.opacity = 0.0
            }
        }

        return node
    }
}

/// Filter Chip - Toggleable selection chip
public struct FilterChip: View, BuiltinView {
    let title: String
    let isSelected: Binding<Bool>
    let selectedColor: Color
    let unselectedColor: Color

    public init(
        _ title: String,
        isSelected: Binding<Bool>,
        selectedColor: Color = .m3SecondaryContainer,
        unselectedColor: Color = .m3SurfaceVariant
    ) {
        self.title = title
        self.isSelected = isSelected
        self.selectedColor = selectedColor
        self.unselectedColor = unselectedColor
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let selected = isSelected.wrappedValue
        let bgColor = selected ? selectedColor : unselectedColor
        let textColor = selected ? Color.m3OnSecondaryContainer : Color.m3OnSurfaceVariant

        let node = Node(color: bgColor)
        node.paddingTop = 8
        node.paddingBottom = 8
        node.paddingLeading = 16
        node.paddingTrailing = 16
        node.cornerRadius = 100  // Fully rounded pill
        node.borderColor = selected ? .clear : .m3Outline
        node.borderWidth = selected ? 0 : 1
        node.layoutType = .zStack
        node.alignment = .center

        if selected {
            node.shadowColor = Color(r: 0, g: 0, b: 0, a: 0.06)
            node.shadowBlur = 4
        }

        let label = Node(color: .clear)
        label.text = title
        label.textColor = textColor
        label.fontSize = 14

        node.children = [label]

        let animation = Animation.easeOut(duration: 0.2)
        node.animationConfig = animation

        node.onClick = {
            self.isSelected.wrappedValue = !self.isSelected.wrappedValue
        }

        // Ripple Animation
        node.onPress = { [weak node] in
            guard let node = node else { return }
            let ripple = Node(color: Color(r: 0.05, g: 0.11, b: 0.22, a: 0.2))
            let size = max(node.frame.w, node.frame.h) * 2.5
            ripple.minW = size
            ripple.minH = size
            ripple.cornerRadius = size / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.0
            ripple.scaleY = 0.0
            ripple.marginLeft = (node.frame.w - size) / 2
            ripple.marginTop = (node.frame.h - size) / 2

            node.children.insert(ripple, at: 0)

            let animation = Animation.easeOut(duration: 0.5)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = 1.0
            ripple.scaleY = 1.0
        }
        node.onRelease = { [weak node] in
            if let ripple = node?.children.first {
                ripple.opacity = 0.0
            }
        }

        return node
    }
}

/// Input Chip - Chip with optional close action
public struct InputChip: View, BuiltinView {
    let title: String
    let onClose: (() -> Void)?
    let bgColor: Color

    public init(
        _ title: String,
        bgColor: Color = .m3SurfaceVariant,
        onClose: (() -> Void)? = nil
    ) {
        self.title = title
        self.bgColor = bgColor
        self.onClose = onClose
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: bgColor)
        node.paddingTop = 8
        node.paddingBottom = 8
        node.paddingLeading = 12
        node.paddingTrailing = onClose != nil ? 8 : 12
        node.cornerRadius = 100  // Fully rounded pill
        node.layoutType = .hStack

        let label = Node(color: .clear)
        label.text = title
        label.textColor = .m3OnSurfaceVariant
        label.fontSize = 14

        var children: [Node] = [label]

        if let closeAction = onClose {
            let closeBtn = Node(color: Color(r: 0, g: 0, b: 0, a: 0.1))
            closeBtn.minW = 18
            closeBtn.minH = 18
            closeBtn.cornerRadius = 9
            closeBtn.marginLeft = 8

            let closeIcon = Node(color: .clear)
            closeIcon.text = "×"
            closeIcon.textColor = .m3OnSurfaceVariant
            closeIcon.fontSize = 14

            closeBtn.children = [closeIcon]
            closeBtn.onClick = closeAction
            children.append(closeBtn)
        }

        node.children = children

        // Ripple Animation
        node.onPress = { [weak node] in
            guard let node = node else { return }
            let ripple = Node(color: Color(r: 0.05, g: 0.11, b: 0.22, a: 0.2))
            let size = max(node.frame.w, node.frame.h) * 2.5
            ripple.minW = size
            ripple.minH = size
            ripple.cornerRadius = size / 2
            ripple.opacity = 0.0
            ripple.scaleX = 0.0
            ripple.scaleY = 0.0
            ripple.marginLeft = (node.frame.w - size) / 2
            ripple.marginTop = (node.frame.h - size) / 2

            node.children.append(ripple)

            let animation = Animation.easeOut(duration: 0.5)
            ripple.animationConfig = animation
            ripple.opacity = 1.0
            ripple.scaleX = 1.0
            ripple.scaleY = 1.0
        }
        node.onRelease = { [weak node] in
            if let ripple = node?.children.last {
                ripple.opacity = 0.0
            }
        }

        return node
    }
}

/// Suggestion/Assist Chip - Action chip
public struct SuggestionChip: View {
    let title: String
    let action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Chip(title, bgColor: .m3SurfaceVariant, action: action)
    }
}
