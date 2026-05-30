import Foundation

public class OddLimb: NLimb {
    public override init(n: Int) throws {
        if n % 2 == 0 { throw NumberError.notOdd }
        try super.init(n: n)
    }

    public convenience init(ordinal: Int) throws {
        if ordinal < 0 { throw NumberError.notOrdinal }
        try self.init(n: 2 * ordinal + 1)
    }

    // Random OddLimb with exactly nbit significant bits.
    public override init(nbit: Int) throws {
        try super.init(nbit: nbit)
        g.first.value |= 1   // force odd
        assert(isValid())
    }

    override init(limbChain: LimbChain) throws {
        if limbChain.first.value & 1 == 0 { throw NumberError.notOdd }
        try super.init(limbChain: limbChain)
    }

    override func copy() -> OddLimb { try! OddLimb(limbChain: g.copy()) }

    // Apply Collatz in-place: compute (3n+1)/2^k where k = v₂(3n+1).
    // 3n+1 = n + 2n + 1, computed limb-by-limb with initial carry = 1.
    public func collatz() {
        // Pass 1: compute 3n+1 in-place.
        var carry: UInt64 = 1    // the +1
        var shiftCarry: UInt64 = 0
        var link: LimbLink? = g.first
        while link != nil {
            let x = link!.value
            let shifted = (x << 1) | shiftCarry
            shiftCarry = x >> 63
            let (sum1, ov1) = x.addingReportingOverflow(shifted)
            let (sum2, ov2) = sum1.addingReportingOverflow(carry)
            carry = (ov1 ? 1 : 0) + (ov2 ? 1 : 0)
            link!.value = sum2
            link = link!.next
        }
        let finalVal = shiftCarry + carry   // 0, 1, or 2 — fits in UInt64
        if finalVal > 0 { g.append(value: finalVal) }

        // Pass 2: strip trailing zero bits (divide by 2^k until odd).
        // Remove whole zero limbs first (O(k/64) allocations saved).
        while g.first.value == 0 { try! g.removeFirst() }
        let tz = g.first.value.trailingZeroBitCount
        if tz > 0 {
            var link2: LimbLink? = g.first
            while link2 != nil {
                let nextVal: UInt64 = link2!.next?.value ?? 0
                link2!.value = (link2!.value >> tz) | (nextVal << (64 - tz))
                link2 = link2!.next
            }
            try! g.shave()
        }
    }

    public func collatzed() -> OddLimb {
        let result = copy()
        result.collatz()
        return result
    }

    public func collatzChain() -> [OddLimb] {
        var result: [OddLimb] = [self]
        while result.last! != OddLimb.one {
            result.append(result.last!.collatzed())
        }
        return result
    }

    public static func collatzProbability(ntrial: Int, nbit: Int, nbin: Int) -> HistogramModel {
        var counts: [Int] = []
        for _ in 0..<ntrial {
            let s = try! OddLimb(nbit: nbit)
            var count = 0
            while s.asInt() != 1 {
                s.collatz()
                count += 1
            }
            counts.append(count)
        }
        let data = counts.map { (Double($0), 1.0) }
        let histogram = HistogramModel(data: data, nbin: nbin)
        histogram.toProbability()
        return histogram
    }
}
