import Foundation

// ==========================================
// VELT ANIMATION SYSTEM
// ==========================================
// Hybrid approach combining:
// - Framer Motion's declarative DX
// - SwiftUI's implicit animations
// - Flutter's Tween performance

// MARK: - Easing Curves

/// Easing functions for smooth animation curves
public enum Easing {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    case cubicBezier(x1: Float, y1: Float, x2: Float, y2: Float)

    /// Apply easing to a normalized time value (0-1)
    public func apply(_ t: Float) -> Float {
        switch self {
        case .linear:
            return t
        case .easeIn:
            return t * t
        case .easeOut:
            return 1 - (1 - t) * (1 - t)
        case .easeInOut:
            return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
        case .cubicBezier(let x1, let y1, let x2, let y2):
            return cubicBezier(t: t, x1: x1, y1: y1, x2: x2, y2: y2)
        }
    }

    /// Cubic bezier approximation
    private func cubicBezier(t: Float, x1: Float, y1: Float, x2: Float, y2: Float) -> Float {
        let cx = 3 * x1
        let bx = 3 * (x2 - x1) - cx
        let _ = 1 - cx - bx  // ax not used in simplified implementation
        let cy = 3 * y1
        let by = 3 * (y2 - y1) - cy
        let ay = 1 - cy - by
        return ((ay * t + by) * t + cy) * t
    }
}

// MARK: - Animation Configuration

/// Animation configuration
public struct Animation {
    public var duration: Double
    public var easing: Easing
    public var delay: Double

    public init(duration: Double = 0.3, easing: Easing = .easeInOut, delay: Double = 0) {
        self.duration = duration
        self.easing = easing
        self.delay = delay
    }

    // MARK: Presets

    public static let `default` = Animation()

    public static func linear(duration: Double = 0.3) -> Animation {
        Animation(duration: duration, easing: .linear)
    }

    public static func easeIn(duration: Double = 0.3) -> Animation {
        Animation(duration: duration, easing: .easeIn)
    }

    public static func easeOut(duration: Double = 0.3) -> Animation {
        Animation(duration: duration, easing: .easeOut)
    }

    public static func easeInOut(duration: Double = 0.3) -> Animation {
        Animation(duration: duration, easing: .easeInOut)
    }

    /// Spring animation using damped harmonic oscillator approximation
    public static func spring(stiffness: Float = 300, damping: Float = 20) -> Animation {
        // Convert spring parameters to duration and curve
        // Higher stiffness = faster, higher damping = less bounce
        let duration = Double(4 / sqrt(stiffness) * (1 + damping / 100))
        // Approximate spring with custom bezier
        let dampingRatio = damping / (2 * sqrt(stiffness))
        let x1: Float = 0.25
        let y1: Float = 1.0 + (1 - dampingRatio) * 0.5
        let x2: Float = 0.25
        let y2: Float = 1.0
        return Animation(duration: duration, easing: .cubicBezier(x1: x1, y1: y1, x2: x2, y2: y2))
    }
}

// MARK: - Animatable Value

/// Protocol for values that can be animated
public protocol Animatable {
    static func lerp(from: Self, to: Self, t: Float) -> Self
}

extension Float: Animatable {
    public static func lerp(from: Float, to: Float, t: Float) -> Float {
        return from + (to - from) * t
    }
}

extension Color: Animatable {
    public static func lerp(from: Color, to: Color, t: Float) -> Color {
        return Color(
            r: Float.lerp(from: from.r, to: to.r, t: t),
            g: Float.lerp(from: from.g, to: to.g, t: t),
            b: Float.lerp(from: from.b, to: to.b, t: t),
            a: Float.lerp(from: from.a, to: to.a, t: t)
        )
    }
}

// MARK: - Animation Instance

/// A single running animation
public class AnimationInstance {
    public let id: UUID
    public let animation: Animation
    public var startTime: Double
    public var elapsed: Double = 0
    public var isComplete: Bool = false

    private let updateHandler: (Float) -> Void
    private let completionHandler: (() -> Void)?

    public init(
        animation: Animation,
        startTime: Double,
        update: @escaping (Float) -> Void,
        completion: (() -> Void)? = nil
    ) {
        self.id = UUID()
        self.animation = animation
        self.startTime = startTime + animation.delay
        self.updateHandler = update
        self.completionHandler = completion
    }

    /// Update animation with delta time, returns true if complete
    func update(currentTime: Double) -> Bool {
        if currentTime < startTime {
            return false  // Still waiting for delay
        }

        elapsed = currentTime - startTime
        let progress = min(Float(elapsed / animation.duration), 1.0)
        let easedProgress = animation.easing.apply(progress)

        updateHandler(easedProgress)

        if progress >= 1.0 {
            isComplete = true
            completionHandler?()
            return true
        }
        return false
    }
}

// MARK: - Animation Controller

/// Global animation controller that manages all active animations
public class AnimationController {
    public static let shared = AnimationController()

    private var animations: [UUID: AnimationInstance] = [:]
    private var lastUpdateTime: Double = 0

    private init() {}

    /// Start a new animation
    @discardableResult
    public func animate<T: Animatable>(
        from: T,
        to: T,
        animation: Animation = .default,
        update: @escaping (T) -> Void,
        completion: (() -> Void)? = nil
    ) -> UUID {
        let currentTime = getCurrentTime()

        let instance = AnimationInstance(
            animation: animation,
            startTime: currentTime,
            update: { progress in
                let value = T.lerp(from: from, to: to, t: progress)
                update(value)
            },
            completion: completion
        )

        animations[instance.id] = instance
        needsRender = true
        return instance.id
    }

    /// Update all animations (called each frame)
    public func update() {
        if animations.isEmpty { return }

        let currentTime = getCurrentTime()

        // Directly remove completed animations to avoid array allocation
        for (id, instance) in animations {
            if instance.update(currentTime: currentTime) {
                animations.removeValue(forKey: id)
            }
        }

        // Request render if animations are active
        if !animations.isEmpty {
            needsRender = true
        }

        lastUpdateTime = currentTime
    }

    /// Cancel an animation
    public func cancel(id: UUID) {
        animations.removeValue(forKey: id)
    }

    /// Cancel all animations
    public func cancelAll() {
        animations.removeAll()
    }

    /// Check if any animations are running
    public var hasActiveAnimations: Bool {
        return !animations.isEmpty
    }

    /// Get current time in seconds
    private func getCurrentTime() -> Double {
        return Date().timeIntervalSinceReferenceDate
    }
}

// MARK: - Animated State Wrapper

/// A property wrapper that automatically animates value changes
@propertyWrapper
public class AnimatedState<Value: Animatable & Equatable> {
    private var _value: Value
    private var targetValue: Value
    private var animation: Animation
    private var currentAnimationId: UUID?

    public init(wrappedValue: Value, animation: Animation = .default) {
        self._value = wrappedValue
        self.targetValue = wrappedValue
        self.animation = animation
    }

    public var wrappedValue: Value {
        get { _value }
        set {
            guard newValue != targetValue else { return }
            targetValue = newValue

            // Cancel existing animation
            if let id = currentAnimationId {
                AnimationController.shared.cancel(id: id)
            }

            // Start new animation
            let startValue = _value
            currentAnimationId = AnimationController.shared.animate(
                from: startValue,
                to: newValue,
                animation: animation
            ) { [weak self] value in
                self?._value = value
            }
        }
    }

    public var projectedValue: AnimatedState<Value> { self }

    /// Change the animation configuration
    public func withAnimation(_ newAnimation: Animation) {
        self.animation = newAnimation
    }
}

// MARK: - View Extension for Animation

/// Storage for animated node properties
public class AnimatedNodeState {
    public var targetColor: Color?
    public var animatedColor: Color?
    public var colorAnimationId: UUID?

    public var targetOpacity: Float = 1.0
    public var animatedOpacity: Float = 1.0
    public var opacityAnimationId: UUID?

    public var animation: Animation = .default

    public init() {}
}

/// Global storage for animated states (keyed by node identity)
public var animatedStates: [ObjectIdentifier: AnimatedNodeState] = [:]
