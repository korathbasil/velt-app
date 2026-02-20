import Foundation

// ==========================================
// ROUTER - Web-Inspired Navigation
// ==========================================

/// Defines a route in the application
public struct Route {
    public let path: String
    public let builder: ([String: String]) -> AnyView

    /// Create a new route
    /// - Parameters:
    ///   - path: The URL path pattern (e.g., "/" or "/user/:id")
    ///   - builder: Closure that builds the view, providing extracted path parameters
    public init(_ path: String, builder: @escaping ([String: String]) -> some View) {
        self.path = path
        // Type erasure helper
        self.builder = { params in AnyView(builder(params)) }
    }

    // Helper init for routes without params
    public init(_ path: String, builder: @escaping () -> some View) {
        self.path = path
        self.builder = { _ in AnyView(builder()) }
    }
}

/// The main router class that manages navigation state
public final class Router: ObservableObject {
    public static let shared = Router()

    public let navigator: Navigator
    private var routes: [Route] = []

    // Current path history
    @Published public var history: [String] = []

    public init(navigator: Navigator = Navigator.shared) {
        self.navigator = navigator
        super.init()
    }

    /// Initialize the router with a list of routes
    public func setRoutes(_ routes: [Route]) {
        self.routes = routes
    }

    /// Navigate to a new path
    /// - Parameter path: The destination path (e.g., "/user/42")
    public func go(_ path: String) {
        // 1. Find matching route
        guard let match = matchRoute(path: path) else {
            Logger.warning("No route found for path: \(path)")
            return
        }

        Logger.info("Navigating to: \(path)")

        // 2. Build the view
        let view = match.route.builder(match.params)

        // 3. Update History
        history.append(path)

        // 4. Delegate to low-level Navigator
        // If history has 1 item, it's root
        if history.count == 1 {
            navigator.setRoot(view)
        } else {
            navigator.push(view, key: AnyHashable(path))
        }
    }

    /// Go back one step
    public func back() {
        guard history.count > 1 else { return }

        _ = history.popLast()
        navigator.pop()

        Logger.info("Navigated back to: \(history.last ?? "/")")
    }

    // MARK: - Matching Logic

    private struct RouteMatch {
        let route: Route
        let params: [String: String]
    }

    private func matchRoute(path: String) -> RouteMatch? {
        let pathComponents = path.split(separator: "/", omittingEmptySubsequences: true)

        for route in routes {
            let routeComponents = route.path.split(separator: "/", omittingEmptySubsequences: true)

            // Basic length check (unless wildcard support added later)
            if pathComponents.count != routeComponents.count { continue }

            var params: [String: String] = [:]
            var isMatch = true

            for (i, routeComp) in routeComponents.enumerated() {
                let pathComp = String(pathComponents[i])
                let routeString = String(routeComp)

                if routeString.hasPrefix(":") {
                    // Parameter match
                    let paramName = String(routeString.dropFirst())
                    params[paramName] = pathComp
                } else if routeString != pathComp {
                    // Exact match failed
                    isMatch = false
                    break
                }
            }

            if isMatch {
                return RouteMatch(route: route, params: params)
            }
        }

        return nil
    }
}

/// A convenience wrapper to initialize the Router at the app root
public struct RouterView: View, BuiltinView {
    public init(initialPath: String = "/", routes: [Route]) {
        Router.shared.setRoutes(routes)

        // Only navigate if stack is empty
        if Navigator.shared.stack.isEmpty {
            Router.shared.go(initialPath)
        }
    }

    public var body: Never { fatalError() }

    public func makeNode() -> Node {
        let node = Node(color: .clear)
        node.layoutType = .navigator
        node.navigator = Router.shared.navigator
        // Ensure it fills available space
        node.minW = 100
        node.minH = 100
        node.mainAxisAlignment = .center  // Fill behavior for stacks, but here just sizing
        // We rely on parent layout to give us size, or fill screen if root
        return node
    }
}
