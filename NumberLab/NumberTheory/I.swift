import Foundation

public class I: Hashable, Comparable, CustomStringConvertible {

    let magnitude: N0
    let negative: Bool

    private init(magnitude: N0, negative: Bool) {
        if case .zero = magnitude {
            self.magnitude = .zero
            self.negative = false
        } else {
            self.magnitude = magnitude
            self.negative = negative
        }
    }

    public convenience init(n: N, negative: Bool = false) {
        self.init(magnitude: .n(n: n), negative: negative)
    }

    convenience init(n0: N0, negative: Bool = false) {
        self.init(magnitude: n0, negative: negative)
    }

    public convenience init(int: Int) throws {
        if int == 0 {
            self.init(magnitude: .zero, negative: false)
        } else if int == Int.min {
            throw NumberError.overflow
        } else {
            self.init(magnitude: .n(n: try N(n: Swift.abs(int))), negative: int < 0)
        }
    }

    public static let zero: I = I(magnitude: .zero, negative: false)
    public static let one: I  = I(magnitude: .n(n: N.one), negative: false)

    // MARK: - Hashable / CustomStringConvertible

    public func hash(into hasher: inout Hasher) {
        hasher.combine(negative)
        switch magnitude {
        case .zero:     hasher.combine(0)
        case .n(let n): n.hash(into: &hasher)
        }
    }

    public var description: String {
        switch magnitude {
        case .zero:     return "0"
        case .n(let n): return negative ? "-\(n)" : "\(n)"
        }
    }

    // MARK: - Comparison

    public static func compare(_ lhs: I, _ rhs: I) -> Int {
        switch (lhs.magnitude, rhs.magnitude) {
        case (.zero, .zero):
            return 0
        case (.zero, .n(_)):
            return rhs.negative ? 1 : -1
        case (.n(_), .zero):
            return lhs.negative ? -1 : 1
        case (.n(let ln), .n(let rn)):
            if lhs.negative != rhs.negative { return lhs.negative ? -1 : 1 }
            let cmp = N.compare(ln, rn)
            return lhs.negative ? -cmp : cmp
        }
    }

    public static func == (lhs: I, rhs: I) -> Bool { compare(lhs, rhs) == 0 }
    public static func <  (lhs: I, rhs: I) -> Bool { compare(lhs, rhs) <  0 }
    public static func <= (lhs: I, rhs: I) -> Bool { compare(lhs, rhs) <= 0 }
    public static func >= (lhs: I, rhs: I) -> Bool { compare(lhs, rhs) >= 0 }
    public static func >  (lhs: I, rhs: I) -> Bool { compare(lhs, rhs) >  0 }

    // MARK: - Negation & Absolute Value

    public static prefix func - (operand: I) -> I {
        switch operand.magnitude {
        case .zero:  return .zero
        case .n(_):  return I(magnitude: operand.magnitude, negative: !operand.negative)
        }
    }

    public var abs: I { I(magnitude: magnitude, negative: false) }

    // MARK: - Arithmetic

    public static func + (lhs: I, rhs: I) -> I {
        switch (lhs.magnitude, rhs.magnitude) {
        case (.zero, _): return rhs
        case (_, .zero): return lhs
        case (.n(let ln), .n(let rn)):
            if lhs.negative == rhs.negative {
                return I(n: ln + rn, negative: lhs.negative)
            }
            let cmp = N.compare(ln, rn)
            if cmp == 0 { return .zero }
            return cmp > 0
                ? I(n: ln - rn, negative: lhs.negative)
                : I(n: rn - ln, negative: rhs.negative)
        }
    }

    public static func += (lhs: inout I, rhs: I) { lhs = lhs + rhs }
    public static func -  (lhs: I, rhs: I) -> I  { lhs + (-rhs) }
    public static func -= (lhs: inout I, rhs: I) { lhs = lhs - rhs }

    public static func * (lhs: I, rhs: I) -> I {
        switch (lhs.magnitude, rhs.magnitude) {
        case (.zero, _), (_, .zero): return .zero
        case (.n(let ln), .n(let rn)):
            return I(n: ln * rn, negative: lhs.negative != rhs.negative)
        }
    }

    public static func *= (lhs: inout I, rhs: I) { lhs = lhs * rhs }
}
