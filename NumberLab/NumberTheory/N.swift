import Foundation

// can represent any natural number (0 is not included)
public class N: Hashable, Comparable, CustomStringConvertible {
    let g: BitChain
    static let zero: N = try! N(n: 0)
    
    public init(n: Int) throws {
        if n < 1 { throw NumberError.notNaturalNumber }
        var bitChain: BitChain? = nil
        var r: Int = n
        while r > 0 {
            let half: Int = r >> 1
            let bit: Bool = 2 * half < r
            if bitChain == nil { bitChain = BitChain(value: bit) }
            else { bitChain!.append(value: bit) }
            r = half
        }
        g = bitChain!
        assert(isValid())
    }
    
    public convenience init(ordinal: Int) throws {
        if ordinal < 0 { throw NumberError.notOrdinal }
        try self.init(n: ordinal + 1)
    }
    
    // create random N of length nbit
    public init(nbit: Int) throws {
        if nbit < 1 { throw NumberError.notNaturalNumber }
        let bitChain: BitChain = BitChain(value: true)
        for _ in 0..<(nbit - 1) {
            bitChain.prepend(value: Bool.random())
        }
        g = bitChain
        assert(isValid())
    }
    
    init(bitChain: BitChain) throws {
        if bitChain.isEmpty() { throw NumberError.notNaturalNumber }
        self.g = bitChain.copy()
        try self.g.shave()
        assert(isValid())
    }
    
    public var description: String {
        return "\(asInt())"
    }
    
    func copy() -> N {
        try! N(bitChain: g.copy())
    }
    
    deinit { BitLink.freeAll(bitchain: g) }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(g.count)
        
        // Hash first few and last few bits for variety
        var link: BitLink? = g.first
        var count = 0
        while link != nil && count < 4 {  // First 4 bits
            hasher.combine(link!.value)
            link = link!.next
            count += 1
        }
        
        // Last 4 bits (if number is long enough)
        if g.count > 8 {
            link = g.last.prev?.prev?.prev  // ~4 bits from end
            while link != nil {
                hasher.combine(link!.value)
                link = link!.next
            }
        }
    }
    
    static let one: Odd = try! Odd(n: 1)
    static let two: N = try! N(n: 2)

    public var asBits: String {
        var result: String = ""
        var link: BitLink? = g.first
        while link != nil {
            result += link!.value ? "1" : "0"
            link = link!.next
        }
        return result
    }
    
    func nbit() -> Int { assert(isValid()); return g.count }
    func isValid() -> Bool { (!g.isEmpty()) && g.last.value }
    func isOne() -> Bool { (g.count == 1) && g.last.value }
    func isOdd() -> Bool { g.first.value }

    func halve() -> N0 {
        if isOne() { return .zero }
        let c = copy()
        try! c.shiftLess(1)
        assert(c.isValid())
        return .n(n: c)
    }

    public static func gcd(_ uIn: N, _ vIn: N) -> N {
        var u = uIn.copy()
        var v = vIn.copy()
        var shift = 0

        while !u.isOdd() && !v.isOdd() {
            guard case .n(let hu) = u.halve(), case .n(let hv) = v.halve() else { break }
            u = hu; v = hv; shift += 1
        }
        while !u.isOdd() {
            if case .n(let hu) = u.halve() { u = hu }
        }
        repeat {
            while !v.isOdd() {
                if case .n(let hv) = v.halve() { v = hv }
            }
            if u > v { swap(&u, &v) }
            if u == v { break }
            v = v - u
        } while true

        u.shiftMore(shift)
        return u
    }
    
    // add initial zeroes (multiplies by pow(2,nshift))
    func shiftMore(_ nshift: Int) {
        assert( nshift >= 0 )
        for _ in 0..<nshift {
            g.prepend(value: false)
        }
    }
    
    // try to remove initial bits (divides by pow(2,nshift))
    func shiftLess(_ nshift: Int) throws {
        assert( (nshift >= 0) && (nshift < self.nbit()) )
        for _ in 0..<nshift {
            try g.removeFirst()
        }
    }
    
    // return -1, 0, +1 according to whether self is less than other, equal to other, greater than other
    func compareTo(_ other: N) -> Int {
        assert(isValid() && other.isValid())
        if nbit() < other.nbit() {
            return -1
        } else if nbit() > other.nbit() {
            return 1
        } else {
            var lNextHighest: BitLink? = g.last.prev
            var rNextHighest: BitLink? = other.g.last.prev
            while lNextHighest != nil {
                if lNextHighest!.value != rNextHighest!.value {
                    return lNextHighest!.value ? 1 : -1
                }
                lNextHighest = lNextHighest!.prev
                rNextHighest = rNextHighest!.prev
            }
            return 0
        }
    }
    public static func compare(_ lhs: N, _ rhs: N) -> Int { lhs.compareTo(rhs) }
    public static func < (lhs: N, rhs: N) -> Bool { compare(lhs, rhs) < 0 }
    public static func <= (lhs: N, rhs: N) -> Bool { compare(lhs, rhs) <= 0 }
    public static func == (lhs: N, rhs: N) -> Bool { compare(lhs, rhs) == 0 }
    public static func >= (lhs: N, rhs: N) -> Bool { compare(lhs, rhs) >= 0 }
    public static func > (lhs: N, rhs: N) -> Bool { compare(lhs, rhs) > 0 }
    
    // Overloading the '+=' operator
    static func +=(lhs: inout N, rhs: N) { lhs = lhs + rhs }
    // Overloading the '+' operator
    static func +(lhs: N, rhs: N) -> N {
        assert(lhs.isValid() && rhs.isValid())
        var carry: Bool = false
        var value: Bool
        (value, carry) = halfAdd(lhs.g.first.value, rhs.g.first.value, carry)
        let bitChain: BitChain = BitChain(value: value)
        var lBitlink: BitLink? = lhs.g.first.next
        var rBitlink: BitLink? = rhs.g.first.next
        while lBitlink != nil || rBitlink != nil {
            let l: Bool = lBitlink?.value ?? false
            let r: Bool = rBitlink?.value ?? false
            (value, carry) = halfAdd(l, r, carry)
            bitChain.append(value: value)
            lBitlink = lBitlink?.next ?? nil
            rBitlink = rBitlink?.next ?? nil
        }
        if carry {
            bitChain.append(value: carry)
        }
        return try! N(bitChain: bitChain)
    }
    
    // Overloading the '*=' operator
    static func *=(lhs: inout N, rhs: N) { lhs = lhs * rhs }
    // Overloading the '*' operator
    static func *(lhs: N, rhs: N) -> N {
        assert(lhs.isValid() && rhs.isValid())
        let lhsShift: N = lhs.copy()
        var sum: N? = nil
        var rBitlink: BitLink? = rhs.g.first
        while rBitlink != nil {
            if rBitlink!.value {
                sum = ( sum == nil ) ? lhsShift.copy() : lhsShift + sum!
            }
            lhsShift.shiftMore(1)
            rBitlink = rBitlink!.next
        }
        return sum!
    }
    
    // Overloading the '-=' operator
    static func -=(lhs: inout N, rhs: N) { lhs = lhs - rhs }
    // Overloading the '-' operator
    static func -(lhs: N, rhs: N) -> N {
        assert(lhs.isValid() && rhs.isValid() && (lhs > rhs))
        // this will be mutated due to borrowing
        let lhsDy: N = lhs.copy()
        var borrowed: Bool
        var value: Bool
        (value, borrowed) = halfSubtract(lhsDy.g.first.value, rhs.g.first.value)
        if borrowed {
            let ok: Bool = lhsDy.g.borrowIn(here: lhsDy.g.first)
            assert(ok)
        }
        let bitChain: BitChain = BitChain(value: value)
        var lBitlink: BitLink? = lhsDy.g.first.next
        var rBitlink: BitLink? = rhs.g.first.next
        while lBitlink != nil {
            let l: Bool = lBitlink!.value
            let r: Bool = rBitlink?.value ?? false
            (value, borrowed) = halfSubtract(l, r)
            if borrowed {
                let ok: Bool = lhsDy.g.borrowIn(here: lBitlink!)
                assert(ok)
            }
            bitChain.append(value: value)
            lBitlink = lBitlink!.next
            rBitlink = rBitlink?.next ?? nil
        }
        return try! N(bitChain: bitChain)
    }
    
    // return the difference a - b and whether borrowing is required to produce it
    static func halfSubtract(_ a: Bool, _ b: Bool) -> (diff: Bool, borrow: Bool) {
        if a {
            return ( !b, false )
        } else {
            return b ? ( true, true ) : ( false, false )
        }
    }
    
    static func halfAdd(_ a: Bool, _ b: Bool, _ carry: Bool) -> (sum: Bool, carry: Bool) {
        if carry {
            return ( (a == b), a || b)
        } else {
            return ( (a != b), a && b)
        }
    }
    
    func asInt() -> Int {
        var result: Int = 0
        var power: Int = 1
        var bit: BitLink? = g.first
        while bit != nil {
            if bit!.value {
                result += power
            }
            power = power << 1
            bit = bit!.next
        }
        return result
    }
    
    // increment in-place
    func inc() {
        var bit: BitLink? = g.first
        // replace 1's with 0's until we encounter a 0 - which we replace with 1 and we're done
        while bit != nil {
            if bit!.value {
                bit!.value = false
                bit = bit!.next
            } else {
                bit!.value = true
                return
            }
        }
        // if we've run out of data we append a 1
        g.append(value: true)
    }
    
    // decrement in-place
    func dec() throws {
        var bitLink: BitLink? = g.first
        // replace 0's with 1's until we encounter a 1 - which we replace with 0 and we're done
        while bitLink != nil {
            if !bitLink!.value {
                bitLink!.value = true
                bitLink = bitLink!.next
            } else {
                bitLink!.value = false
                try g.shave()
                assert(isValid())
                return
            }
        }
        throw NumberError.notNaturalNumber
    }
    
    // remove any powers of 2 in-place
    func sans2() throws {
        var bit: BitLink? = g.first
        // remove all initial 0's
        while bit != nil {
            if bit!.value {
                return
            }
            bit = bit!.next
            try! g.removeFirst()
        }
    }
    
    //  A binary number is divisible by 3 if and only if the alternating sum of its bits
    //  (starting with +1 on the least significant bit) is divisible by 3.
    public func isTriple() -> Bool {
        var polar = 1
        var sum = 0
        var curr: BitLink? = g.first
        while curr != nil {
            if curr!.value {
                sum += polar
            }
            polar = -polar
            curr = curr!.next
        }
        return sum % 3 == 0
    }
    
    // Binary long-division: returns (quotient, remainder) such that self = quotient * divisor + remainder.
    func divide(by divisor: N) -> (quotient: N0, remainder: N0) {
        assert(isValid() && divisor.isValid())
        let cmp = compareTo(divisor)
        if cmp < 0  { return (.zero, .n(n: copy())) }
        if cmp == 0 { return (.n(n: N.one.copy()), .zero) }

        var remainder: N0 = .zero
        var quotientReversed: BitChain? = nil
        var curr: BitLink? = g.last   // iterate MSB → LSB

        while curr != nil {
            let bit = curr!.value
            switch remainder {
            case .zero:
                if bit { remainder = .n(n: N.one.copy()) }
            case .n(let r):
                r.shiftMore(1)
                if bit { r.inc() }
            }

            var qBit = false
            if case .n(let r) = remainder {
                let c = r.compareTo(divisor)
                if c >= 0 {
                    qBit    = true
                    remainder = c == 0 ? .zero : .n(n: r - divisor)
                }
            }

            if quotientReversed == nil { quotientReversed = BitChain(value: qBit) }
            else                        { quotientReversed!.append(value: qBit) }
            curr = curr!.prev
        }

        guard let qr = quotientReversed,
              let rev = try? qr.reverse(),
              let q   = try? N(bitChain: rev) else { return (.zero, remainder) }
        return (.n(n: q), remainder)
    }

    func divideBy3() throws -> (quotient: N0, remainder: Int) {
        switch self {
            case .one: return (.zero, 1)
            case .two: return (.zero, 2)
            default: do {
                var remainder: Int = 0
                var curr: BitLink? = g.last
                var quotientReversed: BitChain? = nil
                while curr != nil {
                    let x = remainder * 2 + (curr!.value ? 1 : 0)
                    let qBit = x / 3
                    remainder = x % 3
                    if quotientReversed == nil {
                        quotientReversed = BitChain(value: qBit == 1)
                    } else {
                        quotientReversed!.append(value: qBit == 1)
                    }
                    curr = curr!.prev
                }
                let quotient = try N(bitChain: quotientReversed!.reverse())
                return (.n(n: quotient), remainder)
            }
        }
    }
}

// can represent any natural number or 0
enum N0 {
    case n (n: N)
    case zero
}

// can represent any natural number (0 is not included)
// count the number of consecutive 0's, then the number of consecutive 1's, ..., the final number of 1's
public class MixedRadix: CustomStringConvertible {
    let mr: [Int]
    
    func isValid() -> Bool { (!mr.isEmpty) && ((mr.count % 2) == 1) }
    public init(n: N) throws {
        assert(n.isValid() && n.g.first.value)
        var mrBuild: [Int] = []

        // leading bit must be 1
        var link: BitLink? = n.g.first
        assert(link!.value)
        var count: Int = 1
        var matchMe: Bool = true
        link = link!.next

        // peel off groups of 1's and groups of 0's
        while link != nil {
            if link!.value == matchMe {
                count += 1
            } else {
                mrBuild.append(count)
                matchMe = !matchMe
                count = 1
            }
            link = link!.next
        }
        mrBuild.append(count)
        mr = mrBuild
        assert(isValid())
    }

    public var description: String {
        var result: String = ""
        var pre: String = ""
        for n in mr {
            result += String("\(pre)\(n)")
            pre = ","
        }
        return result
    }
}
