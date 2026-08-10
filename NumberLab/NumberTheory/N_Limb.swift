import Foundation

public class NLimb: Hashable, Comparable, CustomStringConvertible, CustomDebugStringConvertible {
    let g: LimbChain

    static let one: OddLimb = try! OddLimb(n: 1)
    static let two: NLimb = try! NLimb(n: 2)

    public init(n: Int) throws {
        if n < 1 { throw NumberError.notNaturalNumber }
        g = LimbChain(value: UInt64(n))
    }

    public convenience init(ordinal: Int) throws {
        if ordinal < 0 { throw NumberError.notOrdinal }
        try self.init(n: ordinal + 1)
    }

    // Random NLimb with exactly nbit significant bits.
    public init(nbit: Int) throws {
        if nbit < 1 { throw NumberError.notNaturalNumber }
        let nLimbs   = (nbit + 63) / 64
        let topBits  = ((nbit - 1) % 64) + 1   // 1..64 bits in the MSL

        var chain: LimbChain? = nil
        for i in 0..<nLimbs {
            var limb: UInt64
            if i < nLimbs - 1 {
                limb = UInt64.random(in: 0...UInt64.max)
            } else {
                // MSL: exactly topBits bits, high bit always 1
                if topBits == 64 {
                    limb = UInt64.random(in: 0...UInt64.max) | (UInt64(1) << 63)
                } else {
                    let msb: UInt64 = UInt64(1) << (topBits - 1)
                    let mask: UInt64 = msb | (msb - 1)
                    limb = (UInt64.random(in: 0...mask) | msb) & mask
                }
            }
            if chain == nil { chain = LimbChain(value: limb) }
            else             { chain!.append(value: limb) }
        }
        g = chain!
        assert(isValid())
    }

    init(limbChain: LimbChain) throws {
        if limbChain.isEmpty() { throw NumberError.notNaturalNumber }
        self.g = limbChain.copy()
        try self.g.shave()
        assert(isValid())
    }

    // o * (2**pow2)
    public init(o: Odd, pow2: Int) throws {
        if pow2 < 0 { throw NumberError.notNaturalNumber }
        g = o.g.copy()
        shiftMore(pow2)
        assert(isValid())
    }

    public var description: String {
        g.count == 1 ? "\(g.first.value)" : "\(g.first.value) (truncated, \(g.count) limbs)"
    }
    public var debugDescription: String {
        description
    }

    func copy() -> NLimb { try! NLimb(limbChain: g.copy()) }

    deinit { LimbLink.freeAll(limbchain: g) }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(g.count)
        var link: LimbLink? = g.first
        var count = 0
        while link != nil && count < 2 {
            hasher.combine(link!.value)
            link = link!.next
            count += 1
        }
        if g.count > 4 {
            link = g.last.prev?.prev
            while link != nil {
                hasher.combine(link!.value)
                link = link!.next
            }
        }
    }

    public var asBits: String {
        var result = ""
        var link: LimbLink? = g.first
        while link != nil {
            let limb    = link!.value
            let isLast  = (link!.next == nil)
            let bitCount = isLast ? (64 - limb.leadingZeroBitCount) : 64
            for i in 0..<bitCount {
                result += (limb >> i) & 1 == 1 ? "1" : "0"
            }
            link = link!.next
        }
        return result
    }

    func nbit() -> Int {
        assert(isValid())
        return (g.count - 1) * 64 + (64 - g.last.value.leadingZeroBitCount)
    }

    func isValid() -> Bool { (!g.isEmpty()) && g.last.value != 0 }
    func isOne()   -> Bool { g.count == 1 && g.first.value == 1 }
    func isOdd()   -> Bool { g.first.value & 1 == 1 }

    func halve() -> N0Limb {
        if isOne() { return .zero }
        let c = copy()
        try! c.shiftLess(1)
        assert(c.isValid())
        return .n(n: c)
    }

    // Multiply in-place by 2^nshift (prepend nshift zero bits).
    func shiftMore(_ nshift: Int) {
        assert(nshift >= 0)
        if nshift == 0 { return }
        let limbShift = nshift / 64
        let bitShift  = nshift % 64

        if bitShift > 0 {
            var carry: UInt64 = 0
            var link: LimbLink? = g.first
            while link != nil {
                let newCarry = link!.value >> (64 - bitShift)
                link!.value  = (link!.value << bitShift) | carry
                carry = newCarry
                link = link!.next
            }
            if carry != 0 { g.append(value: carry) }
        }
        for _ in 0..<limbShift { g.prepend(value: 0) }
    }

    // Divide in-place by 2^nshift (remove nshift low-order bits).
    func shiftLess(_ nshift: Int) throws {
        assert(nshift >= 0 && nshift < self.nbit())
        if nshift == 0 { return }
        let limbShift = nshift / 64
        let bitShift  = nshift % 64

        for _ in 0..<limbShift { try g.removeFirst() }

        if bitShift > 0 {
            var link: LimbLink? = g.first
            while link != nil {
                let nextVal: UInt64 = link!.next?.value ?? 0
                link!.value = (link!.value >> bitShift) | (nextVal << (64 - bitShift))
                link = link!.next
            }
            try g.shave()
        }
    }

    func compareTo(_ other: NLimb) -> Int {
        assert(isValid() && other.isValid())
        if g.count < other.g.count { return -1 }
        if g.count > other.g.count { return  1 }
        var lLink: LimbLink? = g.last
        var rLink: LimbLink? = other.g.last
        while lLink != nil {
            if lLink!.value < rLink!.value { return -1 }
            if lLink!.value > rLink!.value { return  1 }
            lLink = lLink!.prev
            rLink = rLink!.prev
        }
        return 0
    }

    public static func compare(_ lhs: NLimb, _ rhs: NLimb) -> Int { lhs.compareTo(rhs) }
    public static func < (lhs: NLimb, rhs: NLimb) -> Bool { compare(lhs, rhs) < 0 }
    public static func <=(lhs: NLimb, rhs: NLimb) -> Bool { compare(lhs, rhs) <= 0 }
    public static func ==(lhs: NLimb, rhs: NLimb) -> Bool { compare(lhs, rhs) == 0 }
    public static func >=(lhs: NLimb, rhs: NLimb) -> Bool { compare(lhs, rhs) >= 0 }
    public static func > (lhs: NLimb, rhs: NLimb) -> Bool { compare(lhs, rhs) > 0 }

    static func +=(lhs: inout NLimb, rhs: NLimb) { lhs = lhs + rhs }
    static func +(lhs: NLimb, rhs: NLimb) -> NLimb {
        assert(lhs.isValid() && rhs.isValid())
        var carry: UInt64 = 0
        var result: LimbChain? = nil
        var lLink: LimbLink? = lhs.g.first
        var rLink: LimbLink? = rhs.g.first

        while lLink != nil || rLink != nil || carry != 0 {
            let l: UInt64 = lLink?.value ?? 0
            let r: UInt64 = rLink?.value ?? 0
            let (sum1, ov1) = l.addingReportingOverflow(r)
            let (sum2, ov2) = sum1.addingReportingOverflow(carry)
            carry = (ov1 ? 1 : 0) + (ov2 ? 1 : 0)   // proved <= 1
            if result == nil { result = LimbChain(value: sum2) }
            else             { result!.append(value: sum2) }
            lLink = lLink?.next
            rLink = rLink?.next
        }
        return try! NLimb(limbChain: result!)
    }

    static func -=(lhs: inout NLimb, rhs: NLimb) { lhs = lhs - rhs }
    static func -(lhs: NLimb, rhs: NLimb) -> NLimb {
        assert(lhs.isValid() && rhs.isValid() && (lhs > rhs))
        var borrow: UInt64 = 0
        var result: LimbChain? = nil
        var lLink: LimbLink? = lhs.g.first
        var rLink: LimbLink? = rhs.g.first

        while lLink != nil {
            let l = lLink!.value
            let r: UInt64 = rLink?.value ?? 0
            let (diff1, uf1) = l.subtractingReportingOverflow(r)
            let (diff2, uf2) = diff1.subtractingReportingOverflow(borrow)
            borrow = (uf1 ? 1 : 0) + (uf2 ? 1 : 0)  // proved <= 1
            if result == nil { result = LimbChain(value: diff2) }
            else             { result!.append(value: diff2) }
            lLink = lLink!.next
            rLink = rLink?.next
        }
        assert(borrow == 0)
        return try! NLimb(limbChain: result!)
    }

    static func *=(lhs: inout NLimb, rhs: NLimb) { lhs = lhs * rhs }
    static func *(lhs: NLimb, rhs: NLimb) -> NLimb {
        assert(lhs.isValid() && rhs.isValid())
        var result: NLimb? = nil
        var rLink: LimbLink? = rhs.g.first
        var limbIdx = 0
        while rLink != nil {
            let b = rLink!.value
            if b != 0 {
                let partial = NLimb.multiplyByLimb(lhs, b)
                for _ in 0..<limbIdx { partial.g.prepend(value: 0) }
                result = result == nil ? partial : result! + partial
            }
            rLink = rLink!.next
            limbIdx += 1
        }
        return result!
    }

    private static func multiplyByLimb(_ n: NLimb, _ b: UInt64) -> NLimb {
        var carry: UInt64 = 0
        var result: LimbChain? = nil
        var link: LimbLink? = n.g.first
        while link != nil {
            let (hi, lo) = b.multipliedFullWidth(by: link!.value)
            let (lo2, ov) = lo.addingReportingOverflow(carry)
            let hi2 = hi &+ (ov ? 1 : 0)
            if result == nil { result = LimbChain(value: lo2) }
            else             { result!.append(value: lo2) }
            carry = hi2
            link = link!.next
        }
        if carry != 0 {
            if result == nil { result = LimbChain(value: carry) }
            else             { result!.append(value: carry) }
        }
        return try! NLimb(limbChain: result!)
    }

    public static func gcd(_ uIn: NLimb, _ vIn: NLimb) -> NLimb {
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

    func asInt() -> Int {
        precondition(g.count == 1 && g.first.value <= UInt64(Int.max),
                     "NLimb.asInt(): value does not fit in Int")
        return Int(g.first.value)
    }

    func inc() {
        var link: LimbLink? = g.first
        while link != nil {
            let (newVal, overflow) = link!.value.addingReportingOverflow(1)
            link!.value = newVal
            if !overflow { return }
            link = link!.next
        }
        g.append(value: 1)
    }

    func dec() throws {
        var link: LimbLink? = g.first
        while link != nil {
            let (newVal, underflow) = link!.value.subtractingReportingOverflow(1)
            link!.value = newVal
            if !underflow {
                try g.shave()
                assert(isValid())
                return
            }
            // Underflow: this limb became UInt64.max; borrow from next.
            link = link!.next
        }
        throw NumberError.notNaturalNumber
    }

    func sans2() throws {
        // Remove all low-order zero bits (divide by 2 until odd).
        while g.first.value == 0 { try g.removeFirst() }
        let tz = g.first.value.trailingZeroBitCount
        if tz > 0 { try shiftLess(tz) }
    }

    public func isTriple() -> Bool {
        // Alternating bit-sum mod 3. Each limb is 64 bits; 64 is even so each
        // limb starts fresh with polar = +1.
        var sum = 0
        var link: LimbLink? = g.first
        while link != nil {
            var limb  = link!.value
            var polar = 1
            for _ in 0..<64 {
                if limb & 1 != 0 { sum += polar }
                polar = -polar
                limb >>= 1
            }
            link = link!.next
        }
        return sum % 3 == 0
    }

    // Binary long-division, bit-by-bit (correctness over speed for the non-Collatz path).
    func divide(by divisor: NLimb) -> (quotient: N0Limb, remainder: N0Limb) {
        assert(isValid() && divisor.isValid())
        let cmp = compareTo(divisor)
        if cmp < 0  { return (.zero, .n(n: copy())) }
        if cmp == 0 { return (.n(n: NLimb.one.copy()), .zero) }

        var remainder: N0Limb = .zero
        var qBits: [Bool] = []

        var curr: LimbLink? = g.last
        while curr != nil {
            let limb     = curr!.value
            let bitCount = curr === g.last ? (64 - limb.leadingZeroBitCount) : 64
            for shift in stride(from: bitCount - 1, through: 0, by: -1) {
                let bit = (limb >> shift) & 1 == 1
                switch remainder {
                case .zero:
                    if bit { remainder = .n(n: NLimb.one.copy()) }
                case .n(let r):
                    r.shiftMore(1)
                    if bit { r.inc() }
                }
                var qBit = false
                if case .n(let r) = remainder {
                    let c = r.compareTo(divisor)
                    if c >= 0 {
                        qBit      = true
                        remainder = c == 0 ? .zero : .n(n: r - divisor)
                    }
                }
                qBits.append(qBit)
            }
            curr = curr!.prev
        }

        var start = 0
        while start < qBits.count && !qBits[start] { start += 1 }
        if start == qBits.count { return (.zero, remainder) }

        var chain: LimbChain? = nil
        var currLimb: UInt64 = 0
        var bitPos = 0
        for i in stride(from: qBits.count - 1, through: start, by: -1) {
            if qBits[i] { currLimb |= (UInt64(1) << bitPos) }
            bitPos += 1
            if bitPos == 64 {
                if chain == nil { chain = LimbChain(value: currLimb) }
                else            { chain!.append(value: currLimb) }
                currLimb = 0; bitPos = 0
            }
        }
        if bitPos > 0 || chain == nil {
            if chain == nil { chain = LimbChain(value: currLimb) }
            else            { chain!.append(value: currLimb) }
        }
        guard let c = chain, let q = try? NLimb(limbChain: c) else { return (.zero, remainder) }
        return (.n(n: q), remainder)
    }

    // Divide by 3 using Knuth-style 128÷64 long division (dividingFullWidth).
    func divideBy3() throws -> (quotient: N0Limb, remainder: Int) {
        if isOne()            { return (.zero, 1) }
        if self == NLimb.two  { return (.zero, 2) }

        var rem: UInt64 = 0
        var qChain: LimbChain? = nil
        var curr: LimbLink? = g.last   // process MSL → LSL

        while curr != nil {
            let (qLimb, newRem) = UInt64(3).dividingFullWidth((high: rem, low: curr!.value))
            rem = newRem
            if qChain == nil { qChain = LimbChain(value: qLimb) }
            else             { qChain!.append(value: qLimb) }
            curr = curr!.prev
        }

        // qChain is MSL-first; reverse to get LSL-first canonical form.
        let quotient = try NLimb(limbChain: qChain!.reverse())
        return (.n(n: quotient), Int(rem))
    }

    // n / 3 if n is a multiple of 3, otherwise nil.
    public func div3() -> N? {
        let (quotient, remainder) = try! divideBy3()
        guard remainder == 0, case .n(let q) = quotient else { return nil }
        return q
    }
}

public enum N0Limb {
    case n(n: NLimb)
    case zero
}
