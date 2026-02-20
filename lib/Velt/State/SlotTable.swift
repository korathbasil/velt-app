import Foundation

// ==========================================
// SLOT TABLE - Compose-inspired Gap Buffer
// ==========================================
// Efficient O(1) storage for composition state with minimal allocations.
// Uses a gap buffer for fast insertions/deletions during recomposition.

/// A slot stores composition information for a single composable unit
public struct Slot {
    /// Unique identity key for this slot
    public let key: AnyHashable

    /// Parent slot index (-1 for root)
    public let parent: Int

    /// Depth in tree (for hierarchy tracking)
    public let depth: Int

    /// The view type name (for diffing)
    public var viewType: String

    /// Stored state values (via remember)
    public var state: [AnyHashable: Any] = [:]

    /// Dependencies this slot reads from
    public var dependencies: Set<ObjectIdentifier> = []

    /// Child slot indices
    public var children: [Int] = []

    /// Whether this slot needs recomposition
    public var isDirty: Bool = true

    /// Associated render node index
    public var renderNodeIndex: Int?

    public init(key: AnyHashable, parent: Int, depth: Int, viewType: String) {
        self.key = key
        self.parent = parent
        self.depth = depth
        self.viewType = viewType
    }
}

/// Gap buffer-based slot table for O(1) insertions during composition
public class SlotTable {
    /// The actual slot storage
    private var slots: [Slot?]

    /// Current capacity
    private var capacity: Int

    /// Gap buffer: start index of the gap
    private var gapStart: Int = 0

    /// Gap buffer: end index of the gap
    private var gapEnd: Int

    /// The composer that owns this table
    public weak var composer: Composer?

    /// Number of active slots
    private(set) public var count: Int = 0

    /// Current composition position (slot index being composed)
    private var cursor: Int = 0

    /// Stack tracking current group hierarchy during composition
    private var groupStack: [(slotIndex: Int, childIndex: Int)] = []

    /// Current active SlotTable for static access from property wrappers
    public static var current: SlotTable?

    /// Current slot index being composed
    public static var currentSlotIndex: Int? {
        current?.groupStack.last?.slotIndex
    }

    /// Free list for slot reuse
    private var freeList: [Int] = []

    public init(initialCapacity: Int = 64) {
        self.capacity = initialCapacity
        self.slots = Array(repeating: nil, count: initialCapacity)
        self.gapEnd = initialCapacity
    }

    // MARK: - Slot Access

    /// Get slot at logical index (accounts for gap)
    public func slot(at index: Int) -> Slot? {
        let physicalIndex = logicalToPhysical(index)
        guard physicalIndex >= 0 && physicalIndex < capacity else { return nil }
        return slots[physicalIndex]
    }

    /// Update slot at logical index
    public func updateSlot(at index: Int, _ update: (inout Slot) -> Void) {
        let physicalIndex = logicalToPhysical(index)
        guard physicalIndex >= 0 && physicalIndex < capacity,
            var slot = slots[physicalIndex]
        else { return }
        update(&slot)
        slots[physicalIndex] = slot
    }

    // MARK: - Composition API

    /// Begin a new composition pass
    public func startComposition() {
        cursor = 0
        groupStack.removeAll()
    }

    /// End composition pass
    public func endComposition() {
        // Any slots after cursor can be considered stale
    }

    /// Begin a group (composable scope) with a key
    /// Returns the slot index and whether it's a new slot
    @discardableResult
    public func beginGroup(key: AnyHashable, viewType: String) -> (index: Int, isNew: Bool) {
        let parentIndex = groupStack.last?.slotIndex ?? -1
        let depth = groupStack.count

        // Check if we can reuse existing slot at cursor
        if let existingSlot = slot(at: cursor), existingSlot.key == key {
            // Reuse existing slot
            let slotIndex = cursor
            groupStack.append((slotIndex: slotIndex, childIndex: 0))
            cursor += 1
            return (slotIndex, false)
        }

        // Need to create new slot
        let newSlot = Slot(key: key, parent: parentIndex, depth: depth, viewType: viewType)
        let slotIndex = insertSlot(newSlot)

        // Update parent's children list
        if parentIndex >= 0 {
            updateSlot(at: parentIndex) { parent in
                if !parent.children.contains(slotIndex) {
                    parent.children.append(slotIndex)
                }
            }
        }

        groupStack.append((slotIndex: slotIndex, childIndex: 0))
        cursor += 1
        return (slotIndex, true)
    }

    /// End the current group
    public func endGroup() {
        guard !groupStack.isEmpty else { return }
        groupStack.removeLast()
    }

    /// Remember a value in the current slot
    public func remember<T>(key: AnyHashable? = nil, calculation: () -> T) -> T {
        guard !groupStack.isEmpty else {
            return calculation()
        }

        let groupIdx = groupStack.count - 1
        let slotIndex = groupStack[groupIdx].slotIndex
        let sequenceKey = key ?? AnyHashable("seq_\(groupStack[groupIdx].childIndex)")
        groupStack[groupIdx].childIndex += 1

        // Check if value exists
        if let existing = slot(at: slotIndex)?.state[sequenceKey] as? T {
            // print("[SLOT] Remember \(sequenceKey): FOUND existing")
            return existing
        }

        // Calculate and store
        // print("[SLOT] Remember \(sequenceKey): CREATING new")
        let value = calculation()
        updateSlot(at: slotIndex) { slot in
            slot.state[sequenceKey] = value
        }
        return value
    }

    /// Check if a value changed (for skipping recomposition)
    public func changed<T: Equatable>(_ value: T, key: AnyHashable = "input") -> Bool {
        guard let currentGroup = groupStack.last else { return true }
        let slotIndex = currentGroup.slotIndex

        if let existing = slot(at: slotIndex)?.state[key] as? T {
            if existing == value {
                return false  // No change
            }
        }

        // Store new value
        updateSlot(at: slotIndex) { slot in
            slot.state[key] = value
        }
        return true
    }

    /// Mark a slot as dirty (needs recomposition)
    public func markDirty(slotIndex: Int) {
        updateSlot(at: slotIndex) { slot in
            slot.isDirty = true
        }
    }

    /// Get all dirty slot indices
    public func dirtySlots() -> [Int] {
        var result: [Int] = []
        result.reserveCapacity(min(count, 16))  // Avoid repeated reallocations
        for i in 0..<count {
            if let s = slot(at: i), s.isDirty {
                result.append(i)
            }
        }
        return result
    }

    /// Fast check if any slots are dirty (avoids array allocation)
    public func hasDirtySlots() -> Bool {
        for i in 0..<count {
            if let s = slot(at: i), s.isDirty { return true }
        }
        return false
    }

    /// Clear dirty flag for a slot
    public func clearDirty(slotIndex: Int) {
        updateSlot(at: slotIndex) { slot in
            slot.isDirty = false
        }
    }

    // MARK: - Gap Buffer Operations

    /// Insert a new slot at the cursor position
    private func insertSlot(_ slot: Slot) -> Int {
        // Check if we need to grow
        if gapStart >= gapEnd {
            grow()
        }

        // Move gap to cursor if needed
        moveGap(to: cursor)

        // Insert at gap start
        slots[gapStart] = slot
        let insertedIndex = gapStart
        gapStart += 1
        count += 1

        return physicalToLogical(insertedIndex)
    }

    /// Move the gap to a specific logical position
    private func moveGap(to position: Int) {
        let physicalPos = logicalToPhysical(position)

        if physicalPos < gapStart {
            // Move gap left
            let moveCount = gapStart - physicalPos
            let gapSize = gapEnd - gapStart
            for i in stride(from: moveCount - 1, through: 0, by: -1) {
                slots[gapEnd - moveCount + i] = slots[physicalPos + i]
                slots[physicalPos + i] = nil
            }
            gapStart = physicalPos
            gapEnd = physicalPos + gapSize
        } else if physicalPos > gapEnd {
            // Move gap right
            let moveCount = physicalPos - gapEnd
            for i in 0..<moveCount {
                slots[gapStart + i] = slots[gapEnd + i]
                slots[gapEnd + i] = nil
            }
            gapStart += moveCount
            gapEnd += moveCount
        }
    }

    /// Grow the buffer when full
    private func grow() {
        let newCapacity = capacity * 2
        var newSlots: [Slot?] = Array(repeating: nil, count: newCapacity)

        // Copy slots before gap
        for i in 0..<gapStart {
            newSlots[i] = slots[i]
        }

        // Copy slots after gap
        let afterGapCount = capacity - gapEnd
        let newGapEnd = newCapacity - afterGapCount
        for i in 0..<afterGapCount {
            newSlots[newGapEnd + i] = slots[gapEnd + i]
        }

        slots = newSlots
        gapEnd = newGapEnd
        capacity = newCapacity
    }

    /// Convert logical index to physical index (accounting for gap)
    private func logicalToPhysical(_ logical: Int) -> Int {
        if logical < gapStart {
            return logical
        } else {
            return logical + (gapEnd - gapStart)
        }
    }

    /// Convert physical index to logical index
    private func physicalToLogical(_ physical: Int) -> Int {
        if physical < gapStart {
            return physical
        } else if physical >= gapEnd {
            return physical - (gapEnd - gapStart)
        } else {
            return -1  // Inside gap
        }
    }
}
