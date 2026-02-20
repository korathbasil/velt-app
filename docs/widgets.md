# Velt Widget Reference

Complete API reference for all Velt UI widgets.

---

## Layout Widgets

### VStack
Vertical stack layout. Supports flex-box style alignment.
```swift
VStack(mainAxisAlignment: .start, crossAxisAlignment: .center, spacing: 10) {
    Text("Item 1")
    Text("Item 2")
}
```
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mainAxisAlignment` | `MainAxisAlignment` | `.start` | Main axis distribution (`.start`, `.center`, `.end`, `.spaceBetween`, `.spaceAround`, `.spaceEvenly`) |
| `crossAxisAlignment` | `CrossAxisAlignment` | `.center` | Cross axis alignment (`.start`, `.center`, `.end`, `.stretch`) |
| `spacing` | `Float` | `0` | Additional fixed spacing between children |
| `alignment` | `CrossAxisAlignment` | `.center` | *Deprecated alias* for `crossAxisAlignment` |

---

### HStack
Horizontal stack layout. Supports flex-box style alignment.
```swift
HStack(mainAxisAlignment: .spaceBetween, crossAxisAlignment: .center) {
    Text("Left")
    Text("Right")
}
```
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mainAxisAlignment` | `MainAxisAlignment` | `.start` | Main axis distribution (`.start`, `.center`, `.end`, `.spaceBetween`, `.spaceAround`, `.spaceEvenly`) |
| `crossAxisAlignment` | `CrossAxisAlignment` | `.center` | Cross axis alignment (`.start`, `.center`, `.end`, `.stretch`) |
| `spacing` | `Float` | `0` | Additional fixed spacing between children |
| `alignment` | `CrossAxisAlignment` | `.center` | *Deprecated alias* for `crossAxisAlignment` |

---

### ZStack
Layered stack (overlay).
```swift
ZStack(alignment: .bottomTrailing) {
    Rectangle(color: .blue)
    Text("Overlay")
}
```
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `alignment` | `Alignment2D` | `.center` | Position of children (`.topLeading`, `.center`, `.bottomTrailing`, etc) |

---

### ScrollView
Scrollable container.
```swift
ScrollView(.vertical, showsIndicators: true) {
    VStack { ... }
}
```
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `axis` | `Axis` | `.vertical` | `.vertical` or `.horizontal` |
| `showsIndicators` | `Bool` | `true` | Show scrollbar |

---

### Grid
Grid layout.
```swift
Grid(columns: 3, spacing: 10) {
    ForEach(items) { ... }
}
```

---

### Center
Centers content in parent.
```swift
Center {
    Text("Centered!")
}
```

---

### SizedBox
Fixed-size box.
```swift
SizedBox(width: 100, height: 50)
```

---

## Text

Full typography support.
```swift
Text("Hello", size: 24, color: .black, weight: .bold)
    .italic()
    .underline()
    .lineLimit(2)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `size` | `Float` | `18` | Font size |
| `color` | `Color` | `.black` | Text color |
| `weight` | `FontWeight` | `.regular` | Font weight |
| `family` | `String` | `"Sans"` | Font family |
| `lineLimit` | `Int?` | `nil` | Max lines |
| `alignment` | `TextAlignment` | `.leading` | Text alignment |

**Modifiers:**
- `.bold()` - Make text bold
- `.italic()` - Make text italic
- `.underline()` - Add underline
- `.strikethrough()` - Add strikethrough
- `.font(size:weight:family:)` - Set font
- `.foregroundColor(_:)` - Set color
- `.kerning(_:)` - Letter spacing

---

## Shapes

### Rectangle
```swift
Rectangle(color: .blue, w: 100, h: 50, cornerRadius: 8)
```

### RoundedRectangle
```swift
RoundedRectangle(cornerRadius: 16, color: .green)
```

### Circle
```swift
Circle(color: .red, size: 50)
```

### Capsule
```swift
Capsule(color: .blue)
```

---

## Interactive Widgets

### Button
Interactive button. Defaults to shrinking to fit its content (label + padding).
```swift
Button("Tap Me", bgColor: .blue, textColor: .white) {
    // action
}

// Custom label:
Button(bgColor: .green, cornerRadius: 12) {
    // action
} label: {
    HStack(spacing: 5) { 
        // Image(...)
        Text("Icon Button") 
    }
}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bgColor` | `Color` | `.blue` | Background |
| `borderColor` | `Color` | `.clear` | Border color |
| `borderWidth` | `Float` | `0` | Border width |
| `cornerRadius` | `Float` | `8` | Corner radius |
| `pressedOpacity` | `Float` | `0.7` | Pressed state opacity |
| `isEnabled` | `Bool` | `true` | Interactive state |

---

### Pressable
Generic interactive wrapper (similar to `InkWell` or `GestureDetector` in other frameworks).
```swift
Pressable {
    Text("Tap Me")
}
.onPress {
    print("Pressed")
}
```

---

### Toggle
Switch control.
```swift
Toggle(isOn: $showFeature, onColor: .green, offColor: .gray, size: .regular)
```
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `onColor` | `Color` | `.green` | On state color |
| `offColor` | `Color` | `.gray` | Off state color |
| `thumbColor` | `Color` | `.white` | Thumb/knob color |
| `size` | `ToggleSize` | `.regular` | `.mini`, `.small`, `.regular`, `.large` |

---

### TextField
Input field.
```swift
TextField("Email", text: $email,
    backgroundColor: .white,
    textColor: .black,
    borderColor: .gray,
    cornerRadius: 8,
    fontSize: 16,
    isSecure: false)
```

---

## Image

```swift
Image("path/to/image.png")
    .resizable()
    .scaledToFit()
    .frame(width: 200, height: 150)
```

**Modifiers:**
- `.resizable()` - Allow scaling
- `.scaledToFit()` - Fit within bounds
- `.scaledToFill()` - Fill bounds (may crop)
- `.frame(width:height:)` - Set target size

---

## Utility Widgets

### Spacer
Flexible space.
```swift
Spacer(minLength: 20)
```

### Divider
```swift
Divider(color: .gray, thickness: 2)
```

### EmptyView
```swift
EmptyView()
```

### ColorView
```swift
ColorView(.blue)  // Fills available space with color
```

---

## View Modifiers

### Layout
```swift
.padding(20)
.padding(.horizontal, 16)
.padding(top: 10, leading: 20, bottom: 10, trailing: 20)
.frame(w: 100, h: 50)
.frame(minWidth: 50, maxWidth: 200, minHeight: 30)
.margin(10)
.marginTop(20)
.cornerRadius(12)
.aspectRatio(16/9, contentMode: .fit)
```

### Styling
```swift
.background(.blue)
.foregroundColor(.white)
.tint(.green)
.border(.red, width: 2)
.shadow(color: .black.opacity(0.3), blur: 10, x: 0, y: 5)
.opacity(0.8)
```

### Visibility
```swift
.hidden()
.visible(condition)
.disabled(true)
.allowsHitTesting(false)
```

### Transforms
```swift
.rotationEffect(45)  // degrees
.scaleEffect(1.5)
.scaleEffect(x: 2, y: 1)
.offset(x: 10, y: -5)
```

### Effects
```swift
.blur(10)
.grayscale(0.5)
.brightness(0.2)
.contrast(1.2)
.saturation(0.8)
```

### Animation
```swift
.animation(.easeInOut(duration: 0.3))
```

### Gestures
```swift
.onTapGesture { }
.onLongPressGesture { }
.onAppear { }
```

### Z-Order
```swift
.zIndex(10)
.clipped()
```

---

## Types

### MainAxisAlignment
For `VStack` and `HStack` main axis distribution.
`.start`, `.center`, `.end`, `.spaceBetween`, `.spaceAround`, `.spaceEvenly`
(Aliases: `.leading`, `.trailing`, `.top`, `.bottom` handled via Start/End)

### CrossAxisAlignment
For `VStack` and `HStack` cross axis alignment.
`.start`, `.center`, `.end`, `.stretch`
(Aliases: `.leading`, `.trailing` map to Start/End)

### Alignment2D
For `ZStack` and absolute positioning.
`.center`, `.top`, `.bottom`, `.leading`, `.trailing`, `.topLeading`, `.topTrailing`, `.bottomLeading`, `.bottomTrailing`

### FontWeight
`.ultraLight`, `.thin`, `.light`, `.regular`, `.medium`, `.semibold`, `.bold`, `.heavy`, `.black`

### TextAlignment
`.leading`, `.center`, `.trailing`

### ContentMode
`.fit`, `.fill`, `.stretch`

### Axis
`.horizontal`, `.vertical`

### ToggleSize
`.mini` (40x24), `.small` (44x26), `.regular` (50x30), `.large` (60x36)

### Edge
`.top`, `.leading`, `.bottom`, `.trailing`

### EdgeSet
`.all`, `.horizontal`, `.vertical`, `.top`, `.leading`, `.bottom`, `.trailing`
