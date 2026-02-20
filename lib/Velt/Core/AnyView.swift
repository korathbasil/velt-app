import Foundation
import ImpellerBackend

public struct AnyView: View, BuiltinView {
    private let _makeNode: () -> Node
    public init<V: View>(_ view: V) { self._makeNode = view.makeNode }
    public var body: Never { fatalError("Accessing AnyView body") }
    func makeNode() -> Node { _makeNode() }
}

extension Never: View {
    public typealias Body = Never
    public var body: Never { fatalError("Never body") }
}
