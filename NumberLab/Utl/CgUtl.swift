// Documentation - https://developer.apple.com/documentation/coregraphics

import Foundation
import SwiftUI
import simd

extension CGPoint {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
    // generate random point within given ranges
    init(xrange: ClosedRange<CGFloat>, yrange: ClosedRange<CGFloat>) {
        self.init(x: CGFloat.random(in: xrange), y: CGFloat.random(in: yrange))
    }
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func +=(left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    mutating func add(_ addMe: CGPoint) {
        self += addMe
    }
    
    mutating func addX(_ addMe: CGFloat) {
        self.x += addMe
    }
    
    mutating func addY(_ addMe: CGFloat) {
        self.y += addMe
    }
    
    static func -=(left: inout CGPoint, right: CGPoint) {
        left = left - right
    }
    
    static func *(scalar: CGFloat, point: CGPoint) -> CGPoint {
        return CGPoint(x: scalar * point.x, y: scalar * point.y)
    }
    
    static func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }

    static func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x / scalar, y: point.y / scalar)
    }

    func scale(_ scale: CGFloat) -> CGPoint {
        return CGPoint(x: scale * self.x, y: scale * self.y)
    }
    
    func normSq() -> CGFloat { return x*x + y*y }
    
    static func normSq(_ points: [CGPoint]) -> CGFloat {
        return points.reduce(0.0) { (partial, point) in
            return partial + (point.x * point.x) + (point.y * point.y)
        }
    }
    
    // Do a linear interpolation between first and last for delta in [0., 1.]
    // If delta is not [0., 1.], it will be a linear extrapolation.
    static func interp(first: CGPoint, last: CGPoint, delta: CGFloat) -> CGPoint {
        let dx = last.x - first.x
        let dy = last.y - first.y
        return CGPoint(x: first.x + delta*dx, y: first.y + delta*dy)
    }
    
    func pointRect(side: CGFloat) -> CGRect {
        let half = 0.5 * side
        return CGRect(x: x - half, y: y - half, width: side, height: side)
    }
    
    func closest(list: [CGPoint]) -> CGPoint? {
        guard !list.isEmpty else { return nil }
        var nearest = list[0]
        var dsqBest = CGPoint.distSq(from: self, to: nearest)
        for idx in 1..<list.count {
            let dsq = CGPoint.distSq(from: self, to: list[idx])
            if dsqBest > dsq {
                dsqBest = dsq
                nearest = list[idx]
            }
        }
        return nearest
    }
    
    static func distSq(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point1.x - point2.x
        let dy = point1.y - point2.y
        return dx * dx + dy * dy
    }

    func normalized() -> CGPoint {
        let len = sqrt(x*x + y*y)
        return len > 0 ? CGPoint(x: x/len, y: y/len) : .zero
    }
}

extension CGSize {
    // return size of each cell in a grid
    static func gridCell(width: CGFloat, height: CGFloat, nRow: Int, nCol: Int, hSpace: CGFloat, vSpace: CGFloat) -> CGSize {
        let w = (width - (CGFloat(nCol - 1) * hSpace)) / CGFloat(nCol)
        let h = (height - (CGFloat(nRow - 1) * vSpace)) / CGFloat(nRow)
        return CGSize(width: w, height: h)
    }
    
    var isLandscape: Bool { self.width >= self.height }
    var isVeryLandscape: Bool { (0.85) * self.width >=  self.height }
}

extension CGRect {
    static func unionOf(_ rects: [CGRect]) -> CGRect? {
       guard !rects.isEmpty else { return nil }
       return rects.reduce(rects[0]) { $0.union($1) }
    }

    static func boundingBox(points: any Collection<CGPoint>) -> CGRect {
        if points.isEmpty { return minBB() }
        let first = points.first!
        var xmin = first.x
        var xmax = first.x
        var ymin = first.y
        var ymax = first.y
        for p in points.dropFirst() {
            xmin = min(p.x, xmin)
            xmax = max(p.x, xmax)
            ymin = min(p.y, ymin)
            ymax = max(p.y, ymax)
        }
        return CGRect(x: xmin, y: ymin, width: xmax - xmin, height: ymax - ymin)
    }
    
    func center() -> CGPoint { CGPoint(x: midX, y: midY) }
    
    func scaleToFit(size: CGSize) -> CGAffineTransform {
        let s: CGFloat = min(size.width / width, size.height / height)
        let scaleT = CGAffineTransform(scaleX: s, y: s)
        return scaleT
    }
    
    func centerScaleToFit(target: CGRect, margin: CGFloat) -> CGAffineTransform {
        let s: CGFloat = (1 - 2 * margin) * min(target.width / width, target.height / height)
        let preCenter = CGAffineTransform(translationX: -midX, y: -midY)
        let scale = CGAffineTransform(scaleX: s, y: s)
        let postCenter = CGAffineTransform(translationX: target.midX, y: target.midY)
        return preCenter.concatenating(scale).concatenating(postCenter)
    }
    
    // useful for empty lists
    static func minBB(x: CGFloat = 0, y: CGFloat = 0) -> CGRect { CGRect(x: x - 0.5, y: y - 0.5, width: 1, height: 1) }
}

struct CGLine {
    var first: CGPoint
    var last: CGPoint
    
    init(first: CGPoint, last: CGPoint) {
        self.first = first
        self.last = last
    }
    
    init(first: CGPoint, last: CGPoint, scale: CGFloat) {
        self.first = first.scale(scale)
        self.last = last.scale(scale)
    }
    
    // generate line point within given ranges
    init(xrange: ClosedRange<CGFloat>, yrange: ClosedRange<CGFloat>) {
        self.first = CGPoint(xrange: xrange, yrange: yrange)
        self.last = CGPoint(xrange: xrange, yrange: yrange)
    }
    
    func add(_ addMe: CGLine) -> CGLine {
        return CGLine( first: self.first + addMe.first, last: self.last + addMe.last )
    }
    
    func subtract(_ subtractMe: CGLine) -> CGLine {
        return CGLine(
            first: self.first - subtractMe.first,
            last: self.last - subtractMe.last
        )
    }
    
    static func dot(_ a: CGLine, _ b: CGLine) -> CGFloat {
        let dA = a.last - a.first
        let dB = b.last - b.first
        return dA.x * dB.x + dA.y * dB.y
    }
    
    func scale(_ scale: CGFloat) -> CGLine {
        return CGLine(
            first: self.first.scale(scale),
            last: self.last.scale(scale)
        )
    }
    
    func normSq() -> CGFloat { return first.normSq() + last.normSq() }
    
    func normalize() -> CGLine? {
        let sq = normSq()
        if sq == 0.0 {
            return nil
        } else {
            return scale( CGFloat(1.0) / sqrt( sq ) )
        }
    }
    
    func midpoint() -> CGPoint { return (first + last).scale(0.5) }
}

struct CGMultiLine: Shape {
    let data: [CGPoint]
    // relative cumulative arc lengths
    let relArcLens: [CGFloat]
    let path: Path
    let bb: CGRect
    
    init(data: [CGPoint]) {
        self.data = data
        let (totalLength, _) = data.reduce((0.0, data.first!)) { partial, point in
            return (partial.0 + sqrt( (point - partial.1).normSq() ), point)
        }
        var prev = data.first!
        var sum: CGFloat = 0.0
        relArcLens = data.map() {
            sum += sqrt( ($0 - prev).normSq() )
            prev = $0
            return CGFloat(sum / totalLength)
        }
        self.path = Self.createPath(data: data)
        self.bb = self.path.boundingRect
    }
    
    func path(in rect: CGRect) -> Path {
        guard !data.isEmpty else { return Path() }
        
        // Calculate scaling factors to fit or fill the rect while maintaining aspect ratio
        let scaleX = rect.width / bb.width
        let scaleY = rect.height / bb.height
        let scale = min(scaleX, scaleY)  // Use min for 'fit' mode (or max for 'fill' mode)
        
        // Calculate translation to center the path in the rect
        let scaledWidth = bb.width * scale
        let scaledHeight = bb.height * scale
        let translateX = rect.minX + (rect.width - scaledWidth) / 2 - bb.minX * scale
        let translateY = rect.minY + (rect.height - scaledHeight) / 2 - bb.minY * scale
        
        // Create transform
        let transform = CGAffineTransform.identity
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: translateX / scale, y: translateY / scale)
        
        // Apply transform to the cached path
        return path.applying(transform)
    }
    
    func getPoint() -> [Double] {
        var result: [Double] = []
        for point in data {
            result.append(point.x)
            result.append(point.y)
        }
        return result
    }
    
    static func createPath(data: [CGPoint]) -> Path {
        var result = Path()
        var idx = 0
        for point in data {
            switch idx {
                case 0: do {
                    result.move(to: point)
                    idx += 1
                }
                default: do {
                    result.addLine(to: point)
                    idx += 1
                }
            }
        }
        return result
    }
    
    // deltas should be a sorted set of relative arc lengths in [0.0, 1.0]
    func interp(deltas: [CGFloat]) -> CGMultiLine? {
        var points: [CGPoint] = []
        for delta in deltas {
            if let point = interp(relArcLen: delta) {
                points.append(point)
            } else {
                return nil
            }
        }
        return CGMultiLine(data: points)
    }
    
    // approximate by the given number of points evenly spaced along the arc length
    func interp(npoint: Int) -> CGMultiLine? {
        let fraction: Double = 1 / Double(npoint - 1)
        let stride: StrideThrough<CGFloat> = stride(from: 0.0, through: CGFloat(1.0 + 0.001*fraction), by: CGFloat.Stride(fraction))
        return interp(deltas: stride.sorted())
    }
    
    // relArcLen in [0.0, 1.0]
    func interp(relArcLen: CGFloat) -> CGPoint? {
        if relArcLen <= 0.0 {
            return data.first!
        } else if relArcLen >= 1.0 {
            return data.last!
        } else {
            for idx in 1..<relArcLens.count {
                if relArcLen <= relArcLens[idx] {
                    let factor = (relArcLen - relArcLens[idx - 1]) / (relArcLens[idx] - relArcLens[idx - 1])
                    return CGPoint.interp(first: data[idx - 1], last: data[idx], delta: factor)
                }
            }
        }
        return nil
    }
    
    static func distanceSq(a: CGMultiLine, b: CGMultiLine) -> CGFloat? {
        let deltas: [CGFloat] = Set(a.relArcLens + b.relArcLens).sorted()
        if let aApprox = a.interp(deltas: deltas) {
            if let bApprox = b.interp(deltas: deltas) {
                var dsq: CGFloat = 0.0
                var deltaPrev: CGFloat = deltas.first!
                var aPrev: CGPoint = aApprox.data.first!
                var bPrev = bApprox.data.first!
                var diffPrev: CGFloat = sqrt( (bPrev - aPrev).normSq() )
                for idx in 1..<deltas.count {
                    let deltaNext: CGFloat = deltas[idx]
                    let aNext = aApprox.data[idx]
                    let bNext = bApprox.data[idx]
                    let diffNext: CGFloat = sqrt( (bNext - aNext).normSq() )
                    let magic = diffPrev * diffNext + ( ( diffNext - diffPrev ) / 3.0 )
                    dsq += magic * (deltaNext - deltaPrev)
                    deltaPrev = deltaNext
                    aPrev = aNext
                    bPrev = bNext
                    diffPrev = diffNext
                }
                return dsq
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    // map the vertices of a multiline to their relative cumulative arc length
    // with the first vertex mapping to 0.0 and the last one to 1.0
    static func toRelativeArcLength(_ data: [CGPoint]) -> [CGFloat] {
        assert(data.count > 1)
        let (totalLength, _) = data.reduce((0.0, data.first!)) { partial, point in
            return (partial.0 + sqrt( (point - partial.1).normSq() ), point)
        }
        var prev = data.first!
        var sum: CGFloat = 0.0
        return data.map() {
            sum += sqrt( ($0 - prev).normSq() )
            prev = $0
            return CGFloat(sum / totalLength)
        }
    }
    
    // find the "midpoint" of a multiline in the sense that half the cumulative arc length
    // comes before it and half comes after it
    func midpoint() -> CGPoint? {
        assert(data.count > 1)
        let (totalLength, _) = data.reduce((0.0, data.first!)) { partial, point in
            return (partial.0 + sqrt( (point - partial.1).normSq() ), point)
        }
        var prev = data.first!
        var sum: CGFloat = 0.0
        let half: CGFloat = 0.5 * totalLength
        for point in data[1...] {
            let len: CGFloat = sqrt( (point - prev).normSq() )
            if sum + len >= half {
                let delta: CGFloat = ( half - sum ) / len
                return CGPoint.interp(first: prev, last: point, delta: delta)
            }
            sum += len
            prev = point
        }
        return nil
    }
    
    // reduce the number of points in a multiline by removing points which can be adequately
    // interpolated from their neighbors
    static func simplify(_ data: [CGPoint], tolerance: CGFloat) -> [CGPoint] {
        var data = data
        if data.count <= 2 {
            return data
        }
        let tolSq = tolerance * tolerance
        while true {
            let lambdas = toRelativeArcLength(data)
            var maxdevSq: CGFloat = 0.0
            var idxMaxdevSq: Int?
            for idx in 1..<data.count-1 {
                let value = CGPoint.interp(first: data.first!, last: data.last!, delta: lambdas[idx])
                let devSq = (value - data[idx]).normSq()
                if maxdevSq < devSq {
                    maxdevSq = devSq
                    idxMaxdevSq = idx
                }
            }
            if maxdevSq <= tolSq {
                return [data.first!, data.last!]
            } else if data.count <= 3 {
                return data
            }
            let nprev = data.count
            let lower = simplify(Array(data[0...idxMaxdevSq!]), tolerance: tolerance)
            let upper = simplify(Array(data[idxMaxdevSq!...]), tolerance: tolerance)
            data = lower + upper[1...]
            if data.count == nprev {
                // simplication has reached a dead end
                return data
            }
        }
    }
}

extension CGAffineTransform {
    // Create transform that combines all three operations:
    // 1. Translate to origin (negative input midpoint)
    // 2. Scale
    // 3. Translate to destination (positive output midpoint)
    static func createTransform(from inputRect: CGRect, to outputRect: CGRect, scale: CGFloat) -> CGAffineTransform {
        return CGAffineTransform.identity
            .translatedBy(x: outputRect.midX, y: outputRect.midY)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -inputRect.midX, y: -inputRect.midY)
    }
    static func createTransformFit(from inputRect: CGRect, to outputRect: CGRect) -> CGAffineTransform {
        let scale = min(outputRect.width / inputRect.width, outputRect.height / inputRect.height)
        return createTransform(from: inputRect, to: outputRect, scale: scale)
    }
    static func createTransformFill(from inputRect: CGRect, to outputRect: CGRect) -> CGAffineTransform {
        let scale = max(outputRect.width / inputRect.width, outputRect.height / inputRect.height)
        return createTransform(from: inputRect, to: outputRect, scale: scale)
    }
}
