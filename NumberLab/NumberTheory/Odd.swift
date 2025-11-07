import Foundation

public class Odd: N {
    public override init(n: Int) throws {
        if n % 2 == 0 { throw NumberError.notOdd }
        do {
            try super.init(n: n)
        } catch {
            throw error
        }
    }
    
    public convenience init(ordinal: Int) throws {
        if ordinal < 0 { throw NumberError.notOrdinal }
        do {
            try self.init(n: 2*ordinal + 1)
        } catch {
            throw error
        }
    }
    
    // create random Odd of length nbit
    public override init(nbit: Int) throws {
        do { try super.init(nbit: nbit) } catch { throw error }
        g.first.value = true
        assert(isValid())
    }
    
    override init(bitChain: BitChain) throws {
        if !bitChain.first.value { throw NumberError.notOdd }
        do {
            try super.init(bitChain: bitChain)
        } catch {
            throw error
        }
    }
    
    override func copy() -> Odd {
        try! Odd(bitChain: g.copy())
    }
    
    public func collatzChain() -> [Odd] {
        var result: [Odd] = [self]
        while result.last! != Odd.one {
            let next:Odd = result.last!.copy()
            next.collatz()
            result.append(next)
        }
        return result
    }
    
    // Perform an in-place collatz: add n to a shifted version of n to get 3*n
    // Starting with a carry bit of 1 thus gives us 3*n + 1
    // Removing initial 0's gives us an Odd result
    public func collatz() {
        var carry: Bool = true
        var current: BitLink? = g.first
        var y: Bool = false
        while current != nil {
            let x: Bool = current!.value
            if carry {
                current!.value = (x == y)
                carry = (x || y)
            } else {
                current!.value = (x != y)
                carry = (x && y)
            }
            y = x
            current = current!.next
        }
        if carry {
            if y {
                g.append(value: false)
                g.append(value: true)
            } else {
                g.append(value: true)
            }
        } else {
            if y {
                g.append(value: true)
            }
        }
        while !g.first.value {
            try! g.removeFirst()
        }
    }
    
    public static func collatzProbability(ntrial: Int, nbit: Int, nbin: Int) -> HistogramModel {
        var counts: [Int] = []
        for _ in 0..<ntrial {
            let s2: Odd = try! Odd(nbit: nbit)
            var count: Int = 0
            while try! s2.asInt() != 1 {
                s2.collatz()
                count += 1
            }
            counts.append(count)
        }
        let data: [(Double, Double)] = counts.map( {(Double($0), 1.0)} )
        let histogram: HistogramModel = HistogramModel(data: data, nbin: nbin)
        histogram.toProbability()
        return histogram
    }
}
