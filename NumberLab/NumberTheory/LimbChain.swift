import Foundation

class LimbChain {
    var first: LimbLink
    var last: LimbLink
    var count: Int  // number of limbs (not bits)

    init(value: UInt64) {
        let limbLink = LimbLink.allocate(value: value)
        self.first = limbLink
        self.last = limbLink
        self.count = 1
    }

    func copy() -> LimbChain {
        var result: LimbChain? = nil
        var link: LimbLink? = self.first
        while link != nil {
            if result == nil {
                result = LimbChain(value: link!.value)
            } else {
                result!.append(value: link!.value)
            }
            link = link!.next
        }
        return result!
    }

    func reverse() throws -> LimbChain {
        var result: LimbChain? = nil
        var link: LimbLink? = self.last
        while link != nil {
            if result == nil {
                result = LimbChain(value: link!.value)
            } else {
                result!.append(value: link!.value)
            }
            link = link!.prev
        }
        try result!.shave()
        return result!
    }

    func isEmpty() -> Bool {
        var link: LimbLink? = self.first
        while link != nil {
            if link!.value != 0 { return false }
            link = link!.next
        }
        return true
    }

    // Remove most-significant zero limbs so that last.value != 0.
    func shave() throws {
        while self.count > 1 && self.last.value == 0 {
            self.removeLast()
        }
        if isEmpty() {
            throw NumberError.notNaturalNumber
        }
    }

    func append(value: UInt64) {
        let link = LimbLink.allocate(value: value)
        self.last.next = link
        link.prev = self.last
        self.last = link
        self.count += 1
    }

    func prepend(value: UInt64) {
        let link = LimbLink.allocate(value: value)
        self.first.prev = link
        link.next = self.first
        self.first = link
        self.count += 1
    }

    func removeFirst() throws {
        if let next: LimbLink = self.first.next {
            next.prev = nil
            self.first.free()
            self.first = next
            self.count -= 1
        } else {
            throw NumberError.emptyChain
        }
    }

    func removeLast() {
        let prev: LimbLink = self.last.prev!
        prev.next = nil
        self.last.free()
        self.last = prev
        self.count -= 1
    }

    // Borrow 2^64 into `here` by finding the nearest more-significant non-zero limb,
    // decrementing it, and setting all zero limbs between it and `here` to UInt64.max.
    // Returns true on success, false if no non-zero limb exists above `here`.
    func borrowIn(here: LimbLink) -> Bool {
        var link: LimbLink? = here.next
        while link != nil {
            if link!.value != 0 {
                link!.value -= 1
                if link!.value == 0 && link!.next == nil {
                    removeLast()
                }
                return true
            } else {
                link!.value = UInt64.max
                link = link!.next
            }
        }
        return false
    }
}

class LimbLink: CustomStringConvertible {
    var value: UInt64
    var next: LimbLink? = nil
    var prev: LimbLink? = nil

    static var freeList: LimbLink? = nil
    static var ntotAlloc: Int = 0
    static let perAlloc: Int = 16 * 1024

    init(value: UInt64) {
        self.value = value
    }

    var description: String {
        let snext = next == nil ? "none" : "\(next!.value)"
        let sprev = prev == nil ? "none" : "\(prev!.value)"
        return "value: \(value) next: \(snext) prev: \(sprev)"
    }

    static func freeAll(limbchain: LimbChain) {
        limbchain.last.next = freeList
        freeList = limbchain.first
    }

    func free() {
        next = LimbLink.freeList
        LimbLink.freeList = self
    }

    func isUnlinked() -> Bool { (next == nil) && (prev == nil) }

    static func allocate(value: UInt64) -> LimbLink {
        if freeList == nil {
            growFreeList(nallocate: perAlloc)
            ntotAlloc += perAlloc
        }
        let nextFree: LimbLink? = freeList!.next
        let result: LimbLink = freeList!
        freeList = nextFree

        result.value = value
        result.next = nil
        result.prev = nil
        return result
    }

    static func growFreeList(nallocate: Int) {
        assert(nallocate > 0)
        for _ in 0..<nallocate {
            let item = LimbLink(value: 0)
            item.next = freeList
            freeList = item
        }
    }
}
