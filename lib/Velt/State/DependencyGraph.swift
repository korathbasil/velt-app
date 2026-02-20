import Foundation

// ==========================================
// DEPENDENCY GRAPH - SwiftUI-inspired DAG
// ==========================================
// Tracks which slots depend on which state for fine-grained invalidation.
// When state changes, only truly affected slots are marked dirty.

/// Tracks dependencies between state objects and slots
public class DependencyGraph {
    /// Map from state object identity to slots that depend on it
    private var stateToSlots: [ObjectIdentifier: Set<Int>] = [:]

    /// Map from slot to states it depends on (for cleanup on slot removal)
    private var slotToStates: [Int: Set<ObjectIdentifier>] = [:]

    /// Weak reference to the slot table for dirty marking
    private weak var slotTable: SlotTable?

    /// Stack of slots being tracked (for nested composition)
    private var trackingStack: [Int] = []

    /// Current slot being tracked
    private var currentTrackingSlot: Int? {
        return trackingStack.last
    }

    public init() {}

    /// Connect to a slot table
    public func connect(to slotTable: SlotTable) {
        self.slotTable = slotTable
    }

    // MARK: - Dependency Tracking

    /// Start tracking reads for a specific slot
    public func startTracking(slot: Int) {
        trackingStack.append(slot)
        print("[DEP GRAPH] Start Tracking Slot \(slot). Stack: \(trackingStack)")

        // Clear old dependencies for this slot
        if let oldStates = slotToStates[slot] {
            for stateId in oldStates {
                stateToSlots[stateId]?.remove(slot)
            }
        }
        slotToStates[slot] = []
    }

    /// Stop tracking reads
    public func stopTracking() {
        if !trackingStack.isEmpty {
            trackingStack.removeLast()
        }
    }

    /// Record that the current slot reads from a state object
    public func trackRead<T: AnyObject>(state: T) {
        guard let slot = currentTrackingSlot else { return }

        let stateId = ObjectIdentifier(state)
        print("[DEP GRAPH] Track Read: \(stateId) -> Slot \(slot)")

        // Add bidirectional mapping
        if stateToSlots[stateId] == nil {
            stateToSlots[stateId] = []
        }
        stateToSlots[stateId]?.insert(slot)

        if slotToStates[slot] == nil {
            slotToStates[slot] = []
        }
        slotToStates[slot]?.insert(stateId)
    }

    // MARK: - Invalidation

    /// Invalidate all slots that depend on a state object
    /// Returns the set of invalidated slot indices
    @discardableResult
    public func invalidate<T: AnyObject>(state: T) -> Set<Int> {
        let stateId = ObjectIdentifier(state)

        guard let affectedSlots = stateToSlots[stateId] else {
            return []
        }
        // print(
        //     "[DEP GRAPH] Invalidate: Found \(affectedSlots.count) affected slots for state \(stateId): \(affectedSlots)"
        // )

        if slotTable == nil {
            Logger.warning("DependencyGraph: Invalidation failed, slotTable is nil")
        }

        // Mark all affected slots as dirty
        for slotIndex in affectedSlots {
            slotTable?.markDirty(slotIndex: slotIndex)
        }

        return affectedSlots
    }

    /// Invalidate by state object identifier directly
    @discardableResult
    public func invalidate(stateId: ObjectIdentifier) -> Set<Int> {
        guard let affectedSlots = stateToSlots[stateId] else {
            return []
        }

        for slotIndex in affectedSlots {
            slotTable?.markDirty(slotIndex: slotIndex)
        }

        return affectedSlots
    }

    // MARK: - Cleanup

    /// Remove all dependencies for a slot (when slot is removed)
    public func removeSlot(_ slotIndex: Int) {
        guard let states = slotToStates[slotIndex] else { return }

        for stateId in states {
            stateToSlots[stateId]?.remove(slotIndex)
            if stateToSlots[stateId]?.isEmpty == true {
                stateToSlots.removeValue(forKey: stateId)
            }
        }

        slotToStates.removeValue(forKey: slotIndex)
    }

    /// Get dependencies for debugging
    public func dependencies(for slot: Int) -> [ObjectIdentifier] {
        return Array(slotToStates[slot] ?? [])
    }

    /// Get affected slots for debugging
    public func affectedSlots<T: AnyObject>(by state: T) -> [Int] {
        let stateId = ObjectIdentifier(state)
        return Array(stateToSlots[stateId] ?? [])
    }
}

// ==========================================
// GLOBAL DEPENDENCY GRAPH INSTANCE
// ==========================================

/// The global dependency graph for the application
public let dependencyGraph = DependencyGraph()
