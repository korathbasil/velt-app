import Foundation
import ImpellerBackend

// ==========================================
// CORE ENGINE - Optimized Render Pipeline
// ==========================================

/// Metrics for the render pipeline (for debugging)
public struct RenderMetrics {
    public var recompositionCount: Int = 0
    public var totalFrames: Int = 0

    public static var current = RenderMetrics()
}

/// Starts the Velt Application with optimized render pipeline
/// Uses Generics <V: View> because View now has associated types.
public func startApp<V: View>(
    _ app: V, width: Int32 = 360, height: Int32 = 800, debug: Bool = false
) {
    Logger.info("Starting VeltApp (\(width)x\(height))...")

    // 1. Initialize Backend
    impeller_init(width, height)

    // 2. Load Default Font
    if !impeller_load_font("Assets/Fonts/ComicNeue-BoldItalic.ttf", "Sans") {
        Logger.warning(
            "Could not load 'Assets/Fonts/ComicNeue-BoldItalic.ttf'. Text may not render.")
    }

    // 3. State
    var wasMouseDown = false
    var activeNode: Node?
    var focusedNode: Node?  // Track keyboard focus
    var currentWidth = Int(width)
    var currentHeight = Int(height)

    // 4. Initial composition (builds slot table)
    composer.startComposition()
    let (_, rootRenderNode) = composer.compose(app, key: "root")
    composer.endComposition()
    composer.rootRenderNode = rootRenderNode

    needsRender = true

    // 5. Game Loop
    while !impeller_window_should_close() {
        // Poll events at the start so we have fresh input and window size
        impeller_poll_events()

        var w: Int32 = 0
        var h: Int32 = 0
        impeller_get_window_size(&w, &h)

        if w != Int32(currentWidth) || h != Int32(currentHeight) {
            currentWidth = Int(w)
            currentHeight = Int(h)
            if debug { Logger.info("Window resized to \(w)x\(h)") }
            impeller_update_window_size(w, h)
            needsRender = true

            // Force layout update on root
            if let root = composer.rootRenderNode {
                root.frame = (0, 0, Float(currentWidth), Float(currentHeight))
                root.markNeedsLayout()
            }
        }

        // A. Update animations
        AnimationController.shared.update()

        // B. Recompose & Layout only if dirty or needed
        if needsRender || composer.rootRenderNode == nil {
            needsRender = false  // Clear at the start of the block!

            if composer.rootRenderNode == nil {
                composer.startComposition()
                let (_, node) = composer.compose(app, key: "root")
                composer.rootRenderNode = node
                composer.endComposition()
            } else {
                composer.recomposeDirty(rootView: app)
            }

            // 1b. Recompose Navigation Stack (Isolated Composers)
            // Each screen has its own composer/dependency graph that needs to process updates
            for entry in Navigator.shared.stack {
                entry.composer.recomposeDirty(rootView: entry.view, key: entry.key)
            }

            // 1. Layout the DSL Root
            if let root = composer.rootRenderNode {
                // Only layout if dirty (logic inside performLayout now checks needsLayout)
                root.performLayout(maxWidth: Float(currentWidth), maxHeight: Float(currentHeight))
                root.frame = (0, 0, Float(currentWidth), Float(currentHeight))
            }
        }

        RenderMetrics.current.totalFrames += 1

        // C. Render Pass (ALWAYS run this to keep FPS counter alive and UI responsive)
        // Clear screen (White background)
        impeller_draw_rect(0, 0, Float(currentWidth), Float(currentHeight), 1, 1, 1, 1)

        // C1. Paint the DSL Root (static background/wrapper)
        if let root = composer.rootRenderNode {
            root.paint(offsetX: 0, offsetY: 0)
        }

        // D. FPS Overlay (rendered from C++)
        impeller_draw_fps_overlay()

        // G. Swap
        impeller_swap_buffers()

        // E. Input Handling
        let isMouseDown = impeller_is_mouse_down()
        var cursorX: Double = 0
        var cursorY: Double = 0
        impeller_get_cursor_pos(&cursorX, &cursorY)

        if isMouseDown && !wasMouseDown {
            if debug { Logger.info("Mouse Down at (\(cursorX), \(cursorY))") }
            // Mouse Down (use simulated or real coords)
            let x = cursorX
            let y = cursorY

            // Hit Test (Root)
            var hitTarget: RenderNode? = nil
            if let root = composer.rootRenderNode {
                hitTarget = root.hitTest(x: Float(x), y: Float(y))
            }

            if let clickedRenderNode = hitTarget {
                if debug { Logger.success("Hit leaf node: \(clickedRenderNode)") }

                // Walk up to find nearest interactive node
                var current: RenderNode? = clickedRenderNode
                var foundInteractive = false

                while let rnode = current {
                    if let node = rnode.node {
                        // Check for Input/Focus
                        if node.onInput != nil {
                            focusedNode = node
                            foundInteractive = true
                        }

                        if node.onPress != nil || node.onClick != nil {
                            activeNode = node
                            node.onPress?()
                            foundInteractive = true
                            break
                        }
                    }
                    current = rnode.parent
                }

                // If we clicked something but found no input handler, clear focus (Blur)
                if !foundInteractive {
                    // Start from leaf again to see if we clicked background
                    // Actually, if we hit *any* node but no one claimed focus, blur.
                    // But if we clicked a child of a focused node?
                    // Usually simple logic: Click non-focusable -> Blur.
                    focusedNode = nil
                }
            } else {
                if debug { Logger.warning("No hit at (\(x), \(y))") }
                focusedNode = nil  // Clicked void -> Blur
            }
        } else if !isMouseDown && wasMouseDown {
            // Mouse Up - trigger onClick here (standard behavior)
            if let node = activeNode {
                if debug {
                    Logger.info("Mouse Up: triggering handlers for node type \(type(of: node))")
                }
                node.onRelease?()
                if let click = node.onClick {
                    if debug { Logger.success("  Executing onClick!") }
                    click()
                } else {
                    if debug { Logger.warning("  No onClick handler found on activeNode") }
                }
                activeNode = nil
            } else {
                if debug { Logger.info("Mouse Up: no activeNode to trigger") }
            }
        }
        wasMouseDown = isMouseDown

        // Scroll Handling
        var scrollX: Double = 0
        var scrollY: Double = 0
        impeller_get_scroll_delta(&scrollX, &scrollY)

        if scrollX != 0 || scrollY != 0 {
            // Hit Test for Scroll Target
            var hitTarget: RenderNode? = nil
            if let root = composer.rootRenderNode {
                hitTarget = root.hitTest(x: Float(cursorX), y: Float(cursorY))
            }

            if let target = hitTarget {
                // Walk up to find scrollable
                var current: RenderNode? = target
                while let rnode = current {
                    if let node = rnode.node, node.layoutType == .scroll {
                        // Found scrollable!
                        node.onScroll?(Float(scrollX), Float(scrollY))
                        needsRender = true
                        break
                    }
                    current = rnode.parent
                }
            }
        }

        // Keyboard Handling
        if let focused = focusedNode {
            while true {
                let code = impeller_get_next_char()
                if code == 0 { break }

                if code == 0x08 {  // Backspace
                    focused.onInput?(.backspace)
                    needsRender = true
                } else if let scalar = UnicodeScalar(code) {
                    let c = Character(scalar)
                    focused.onInput?(.char(c))
                    needsRender = true
                }
            }
        } else {
            // Drain queue if no focus to prevent buffer buildup
            while impeller_get_next_char() != 0 {}
        }

        // F. Yield to RunLoop
        // Reduced sleep to 1ms to allow for high refresh rates (120Hz = 8.3ms frame budget)
        _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.001))
    }

    // 6. Cleanup
    impeller_shutdown()
    Logger.success("App Closed.")
    Logger.info("Total frames: \(RenderMetrics.current.totalFrames)")
    Logger.info("Total recompositions: \(RenderMetrics.current.recompositionCount)")
}
