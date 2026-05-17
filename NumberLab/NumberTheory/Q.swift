import Foundation

public class Q: Hashable, Comparable, CustomStringConvertible {

    let numerator: I    // carries sign; .zero when Q is zero
    let denominator: N  // always positive (≥ 1); N.one when numerator is zero

    // Designated init: reduces numerator/denominator by their GCD.
    private init(_ numerator: I, _ denominator: N) {
        switch numerator.magnitude {
        case .zero:
            self.numerator   = .zero
            self.denominator = N.one.copy()
        case .n(let nm):
            let g = N.gcd(nm, denominator)
            let (qNum, _) = nm.divide(by: g)
            let (qDen, _) = denominator.divide(by: g)
            if case .n(let rn) = qNum, case .n(let rd) = qDen {
                self.numerator   = I(n: rn, negative: numerator.negative)
                self.denominator = rd
            } else {
                self.numerator   = numerator
                self.denominator = denominator
            }
        }
    }

    public convenience init(numerator: I, denominator: N) {
        self.init(numerator, denominator)
    }

    public convenience init(i: I) {
        self.init(i, N.one.copy())
    }

    public convenience init(int: Int) throws {
        self.init(i: try I(int: int))
    }

    public static let zero: Q = Q(.zero,  N.one.copy())
    public static let one:  Q = Q(I.one,  N.one.copy())

    // MARK: - Hashable / CustomStringConvertible

    public func hash(into hasher: inout Hasher) {
        numerator.hash(into: &hasher)
        denominator.hash(into: &hasher)
    }

    public var description: String {
        switch numerator.magnitude {
        case .zero:          return "0"
        case _ where denominator.isOne(): return numerator.description
        default:             return "\(numerator)/\(denominator)"
        }
    }

    // MARK: - Comparison

    public static func compare(_ lhs: Q, _ rhs: Q) -> Int {
        // lhs.num/lhs.den vs rhs.num/rhs.den
        // ↔  lhs.num * rhs.den vs rhs.num * lhs.den   (dens are positive so inequality preserved)
        let l = lhs.numerator * I(n: rhs.denominator)
        let r = rhs.numerator * I(n: lhs.denominator)
        return I.compare(l, r)
    }

    public static func == (lhs: Q, rhs: Q) -> Bool { compare(lhs, rhs) == 0 }
    public static func <  (lhs: Q, rhs: Q) -> Bool { compare(lhs, rhs) <  0 }
    public static func <= (lhs: Q, rhs: Q) -> Bool { compare(lhs, rhs) <= 0 }
    public static func >= (lhs: Q, rhs: Q) -> Bool { compare(lhs, rhs) >= 0 }
    public static func >  (lhs: Q, rhs: Q) -> Bool { compare(lhs, rhs) >  0 }

    // MARK: - Negation

    public static prefix func - (operand: Q) -> Q {
        Q(-operand.numerator, operand.denominator.copy())
    }

    public var abs: Q { Q(numerator.abs, denominator.copy()) }

    // MARK: - Arithmetic

    public static func + (lhs: Q, rhs: Q) -> Q {
        // (p1/q1) + (p2/q2) = (p1*q2 + p2*q1) / (q1*q2)
        let num = lhs.numerator * I(n: rhs.denominator) + rhs.numerator * I(n: lhs.denominator)
        let den = lhs.denominator * rhs.denominator
        return Q(num, den)
    }

    public static func += (lhs: inout Q, rhs: Q) { lhs = lhs + rhs }
    public static func -  (lhs: Q, rhs: Q) -> Q  { lhs + (-rhs) }
    public static func -= (lhs: inout Q, rhs: Q) { lhs = lhs - rhs }

    public static func * (lhs: Q, rhs: Q) -> Q {
        // (p1/q1) * (p2/q2) = (p1*p2) / (q1*q2)
        return Q(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)
    }

    public static func *= (lhs: inout Q, rhs: Q) { lhs = lhs * rhs }

    // Throws if rhs is zero.
    public static func / (lhs: Q, rhs: Q) throws -> Q {
        // (p1/q1) / (p2/q2) = (p1 * q2) / (q1 * |p2|)
        // Sign of rhs absorbed into numerator via I(n: rhs.denominator, negative: rhs.numerator.negative)
        switch rhs.numerator.magnitude {
        case .zero: throw NumberError.notNaturalNumber
        case .n(let rn):
            let num = lhs.numerator * I(n: rhs.denominator, negative: rhs.numerator.negative)
            let den = lhs.denominator * rn
            return Q(num, den)
        }
    }
}
