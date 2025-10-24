import Foundation

class BitChain {
    var first: BitLink
    var last: BitLink
    var count: Int
    
    init(value: Bool) {
        let bitLink = BitLink.allocate(value: value)
        self.first = bitLink
        self.last = bitLink
        self.count = 1
    }
    
    // copy
    func copy() -> BitChain {
        var result: BitChain? = nil
        var bitLink: BitLink? = self.first
        while bitLink != nil {
            if result == nil {
                result = BitChain(value: bitLink!.value)
            } else {
                result!.append(value: bitLink!.value)
            }
            bitLink = bitLink!.next
        }
        return result!
    }
    
    // if all bits are 0, it is empty
    func isEmpty() -> Bool {
        var bit: BitLink? = self.first
        while bit != nil {
            if bit!.value { return false }
            bit = bit!.next
        }
        return true
    }
    
    // recursively remove MSG (most significant bit) if it is 0
    func shave() throws {
        while !self.last.value {
            self.removeLast()
        }
        if isEmpty() {
            throw NumberError.notNaturalNumber
        }
    }
    
    func append(value: Bool) {
        let bitLink = BitLink.allocate(value: value)
        self.last.next = bitLink
        bitLink.prev = self.last
        self.last = bitLink
        self.count += 1
    }
    
    func prepend(value: Bool) {
        let bitLink = BitLink.allocate(value: value)
        self.first.prev = bitLink
        bitLink.next = self.first
        self.first = bitLink
        self.count += 1
    }
    
    func removeFirst() throws {
        if let next: BitLink = self.first.next {
            next.prev = nil
            self.first.free()
            self.first = next
            self.count -= 1
        } else {
            throw NumberError.emptyChain
        }
    }
    
    func removeLast() {
        let prev: BitLink = self.last.prev!
        prev.next = nil
        self.last.free()
        self.last = prev
        self.count -= 1
    }
    
    // For subtraction, when a link of the minuend is 0 and we need it to be 1 we try to borrow from
    // the nearest more significant link that is a 1.
    // In the process, all of the 0 links that are visited are turned into 1's, and the link that is
    // finally borrowed from is made 0.
    // The link that does the borrowing ("here") is normally a 0 and is not changed - it's as if the
    // borrowed 1 was leaked in the subtraction process and in long division "here" and other links
    // of lower significance are throwaways at this point. (It's a good practise to use a cloned
    // N as the minuend and then just discard it.)
    // If we borrow succesfully a true is returned, otherwise a false.
    func borrowIn(here: BitLink) -> Bool {
        var link: BitLink? = here.next
        while link != nil {
            if link!.value {
                link!.value = false
                if link!.next == nil {
                    removeLast()
                }
                return true
            } else {
                link!.value = true
                link = link!.next
            }
        }
        return false
    }
    
}

class BitLink: CustomStringConvertible {
    var value: Bool
    var next: BitLink? = nil
    var prev: BitLink? = nil
    
    static var freeList: BitLink? = nil
    static var ntotAlloc: Int = 0
    static let perAlloc: Int = 16 * 1024

    init(value: Bool) {
        self.value = value
    }
    
    var description: String {
        let snext: String = next == nil ? "none" : "\(next!.value)"
        let sprev: String = prev == nil ? "none" : "\(prev!.value)"
        return String("value: \(value) next: \(snext) prev: \(sprev)")
    }

    static func freeAll(bitchain: BitChain) {
        bitchain.last.next = freeList
        freeList = bitchain.first
    }
    func free() {
        next = BitLink.freeList
        BitLink.freeList = self
    }
    func isUnlinked() -> Bool { (next == nil) && (prev == nil) }

    static func allocate(value: Bool) -> BitLink {
        if freeList == nil {
            growFreeList(nallocate: perAlloc)
            ntotAlloc += perAlloc
        }
        let nextFree: BitLink? = freeList!.next
        let result: BitLink = freeList!
        freeList = nextFree
        
        result.value = value
        result.next = nil
        result.prev = nil
        return result
    }
    
    static func growFreeList(nallocate: Int) {
        assert(nallocate > 0)
        for _ in 0..<nallocate {
            let item = BitLink(value: false)
            item.next = freeList
            freeList = item
        }
    }
}
