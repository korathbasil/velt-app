import Foundation
import ImpellerBackend

public struct Image: View, BuiltinView {
    let path: String
    var contentMode: ContentMode
    var tintColor: Color?
    private var isResizable: Bool
    private var targetWidth: Float?
    private var targetHeight: Float?

    public init(_ path: String, contentMode: ContentMode = .fit) {
        self.path = path
        self.contentMode = contentMode
        self.tintColor = nil
        self.isResizable = false
        self.targetWidth = nil
        self.targetHeight = nil
    }

    public var body: Never { fatalError() }

    func makeNode() -> Node {
        let node = Node(color: .clear)
        let id = impeller_load_texture(path)
        if id != 0 {
            node.textureId = Int(id)
            let originalW = Float(impeller_get_texture_width(id))
            let originalH = Float(impeller_get_texture_height(id))

            if isResizable {
                // Use target size if specified, otherwise use original
                node.minW = targetWidth ?? originalW
                node.minH = targetHeight ?? originalH
            } else {
                // Original size
                node.minW = originalW
                node.minH = originalH
            }
        }
        node.layoutType = .leaf
        return node
    }

    // MARK: - Chainable Modifiers

    /// Make the image resizable (scales to fit its container)
    public func resizable() -> Image {
        var copy = self
        copy.isResizable = true
        return copy
    }

    /// Scale to fit within bounds (maintains aspect ratio, may letterbox)
    public func scaledToFit() -> Image {
        var copy = self
        copy.contentMode = .fit
        return copy
    }

    /// Scale to fill bounds (maintains aspect ratio, may crop)
    public func scaledToFill() -> Image {
        var copy = self
        copy.contentMode = .fill
        return copy
    }

    /// Set a tint/overlay color
    public func foregroundColor(_ color: Color) -> Image {
        var copy = self
        copy.tintColor = color
        return copy
    }

    /// Specify target frame for resizable images
    public func frame(width: Float? = nil, height: Float? = nil) -> Image {
        var copy = self
        if let w = width { copy.targetWidth = w }
        if let h = height { copy.targetHeight = h }
        copy.isResizable = true
        return copy
    }
}
