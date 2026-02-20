import Foundation

// Material Design Ripple Effect Helper
// Creates an expanding circular ripple animation from center
public class RippleEffect {
    /// Add ripple effect to a node
    /// - Parameters:
    ///   - node: The target node to add ripple to
    ///   - color: Ripple color (typically white or black with low opacity)
    ///   - duration: Animation duration in seconds
    public static func addRipple(
        to node: Node, color: Color = Color(r: 1, g: 1, b: 1, a: 0.3), duration: Float = 0.4
    ) {
        // Create ripple overlay
        let ripple = Node(color: color)
        let size = max(node.frame.w, node.frame.h) * 2.5  // Ensure full coverage
        ripple.minW = size
        ripple.minH = size
        ripple.cornerRadius = size / 2  // Make it circular
        ripple.opacity = 0.0  // Start invisible

        // Position at center
        ripple.frame = (
            x: (node.frame.w - size) / 2,
            y: (node.frame.h - size) / 2,
            w: size,
            h: size
        )

        // Set up animation
        let animation = Animation.easeOut(duration: TimeInterval(duration))
        ripple.animationConfig = animation

        // Add as overlay child
        node.children.append(ripple)

        // Trigger animation after a tiny delay to ensure rendering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            // Animate: fade in quickly, then fade out while scaling
            ripple.opacity = 0.6
            ripple.scaleX = 0.1
            ripple.scaleY = 0.1

            // After brief moment, expand and fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                ripple.opacity = 0.0
                ripple.scaleX = 1.0
                ripple.scaleY = 1.0

                // Remove ripple after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(duration)) {
                    if let index = node.children.firstIndex(where: { $0 === ripple }) {
                        node.children.remove(at: index)
                    }
                }
            }
        }
    }
}
