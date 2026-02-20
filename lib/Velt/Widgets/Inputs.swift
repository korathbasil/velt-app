import Foundation

// ==========================================
// INPUT WIDGETS
// ==========================================

public struct TextField: View, BuiltinView {
    var placeholder: String
    var text: Binding<String>
    var backgroundColor: Color
    var textColor: Color
    var placeholderColor: Color
    var borderColor: Color
    var borderWidth: Float
    var cornerRadius: Float
    var fontSize: Float
    var isSecure: Bool

    // Additional M3 properties
    var label: String?
    var helperText: String?
    var isError: Bool

    // Standard init with Shadcn defaults
    public init(
        _ placeholder: String,
        text: Binding<String>,
        backgroundColor: Color = .white,
        textColor: Color = .black,
        placeholderColor: Color = .gray,
        borderColor: Color = Color(r: 0.88, g: 0.91, b: 0.94, a: 1.0),  // Slate-200
        borderWidth: Float = 1.0,
        cornerRadius: Float = 6,
        fontSize: Float = 14,
        isSecure: Bool = false
    ) {
        self.placeholder = placeholder
        self.text = text
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.placeholderColor = placeholderColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.fontSize = fontSize
        self.isSecure = isSecure
        self.label = nil
        self.helperText = nil
        self.isError = false
    }

    // M3/Shadcn Specific Init (Label support)
    public init(
        label: String,
        text: Binding<String>,
        helperText: String? = nil,
        isError: Bool = false
    ) {
        self.label = label
        self.placeholder = ""
        self.text = text
        self.helperText = helperText
        self.isError = isError

        self.backgroundColor = .white
        self.textColor = .black
        self.placeholderColor = .gray
        self.borderColor = isError ? .m3Error : Color(r: 0.88, g: 0.91, b: 0.94, a: 1.0)
        self.borderWidth = 1.0
        self.cornerRadius = 6
        self.fontSize = 14
        self.isSecure = false
    }

    /// Convenience initializer for static text (read-only)
    public init(_ placeholder: String, text staticText: String) {
        self.placeholder = placeholder
        self.text = .constant(staticText)
        self.backgroundColor = .white
        self.textColor = .black
        self.placeholderColor = .gray
        self.borderColor = Color(r: 0.88, g: 0.91, b: 0.94, a: 1.0)
        self.borderWidth = 1.0
        self.cornerRadius = 6
        self.fontSize = 14
        self.isSecure = false
        self.label = nil
        self.helperText = nil
        self.isError = false
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        // Text field box
        let box = Node(color: backgroundColor)

        // Size defaults (Shadcn small/medium)
        box.minW = 200
        box.minH = 40

        box.borderWidth = borderWidth
        box.borderColor = borderColor
        box.cornerRadius = cornerRadius
        box.padding = 10  // Comfortable padding
        box.alignment = .leading  // Align text to left-center (Alignment2D.leading implies vertical center)

        let currentText = text.wrappedValue
        let displayText = isSecure ? String(repeating: "•", count: currentText.count) : currentText

        // Input Handling
        box.onInput = { [weak box] event in
            // Need to update binding
            // Since `text` is a Binding struct, we can just write to it?
            // Yes, Binding references an underlying value provided by parent.
            // BUT, `makeNode` is called once (or recomposed).
            // The `text` binding captured here is valid.

            switch event {
            case .char(let c):
                self.text.wrappedValue.append(c)
            case .backspace:
                if !self.text.wrappedValue.isEmpty {
                    self.text.wrappedValue.removeLast()
                }
            }

            // Re-render handled by state change -> recomposition
            // But we need to update the node text immediately for responsiveness?
            // Recomposition will replace this node.
            // But for now, we just update state.
        }

        // Also attach onPress to capture focus?
        // Application logic handles focus if onInput is present.
        // But we might want visual feedback (Focus Ring?).
        // For now, minimal functional implementation.

        // Logic for label vs placeholder
        let actualLabel =
            (label != nil)
            ? (currentText.isEmpty ? label! : currentText)
            : (displayText.isEmpty ? placeholder : displayText)
        let actualColor = (label != nil && currentText.isEmpty) ? placeholderColor : textColor

        let labelNode = Node(color: .clear)
        labelNode.text = actualLabel
        labelNode.textColor = actualColor
        labelNode.fontSize = fontSize

        box.children = [labelNode]

        // Note: helperText and isError are ignored for internal layout to ensure
        // the returned node is strictly the input box, matching Velt expectations.
        // Helper text should be added externally in a VStack.

        return box
    }
}

public struct Toggle: View, BuiltinView {
    var isOn: Binding<Bool>
    var onColor: Color
    var offColor: Color
    var thumbColor: Color
    var size: ToggleSize

    public init(
        isOn: Binding<Bool>,
        onColor: Color = .m3Primary,  // M3 Default
        offColor: Color = .m3SurfaceVariant,  // M3 Default (approx)
        thumbColor: Color = .white,
        size: ToggleSize = .regular
    ) {
        self.isOn = isOn
        self.onColor = onColor
        self.offColor = offColor
        self.thumbColor = thumbColor
        self.size = size
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let currentValue = isOn.wrappedValue

        let trackWidth = size.trackWidth
        let trackHeight = size.trackHeight
        let knobSize = trackHeight - 4
        let padding: Float = 2

        let animation = Animation.easeIn(duration: 0.3)

        let trackColor = currentValue ? onColor : offColor
        let knobX = currentValue ? (trackWidth - knobSize - padding) : padding

        let track = Node(color: trackColor)
        track.minW = trackWidth
        track.minH = trackHeight
        track.cornerRadius = trackHeight / 2
        track.layoutType = .leaf
        track.alignment = .topLeading
        track.animationConfig = animation

        let knob = Node(color: thumbColor)
        knob.frame = (0, 0, knobSize, knobSize)
        knob.cornerRadius = knobSize / 2
        knob.marginLeft = knobX
        knob.marginTop = padding
        knob.animationConfig = animation

        track.children = [knob]
        track.onClick = {
            self.isOn.wrappedValue = !self.isOn.wrappedValue
        }

        return track
    }
}
