import Foundation

public class HistogramModel {
    var min: Double
    var max: Double
    var xscale: Double
    var nbin: Int
    var values: [Double]
    
    let margin: Double = 0.05
    
    public init(data: [(Double,Double)], nbin: Int) {
        assert(!data.isEmpty)
        self.nbin = nbin
        self.min = data.map( {$0.0} ).min()!
        self.max = data.map( {$0.0} ).max()!
        let pad: Double = margin * (self.max - self.min) / Double(self.nbin)
        self.min -= pad
        self.max += pad
        self.xscale = Double(self.nbin) / (self.max - self.min)
        self.values = Array(repeating: 0.0, count: nbin)
        for point in data {
            let idx: Int = Int( (point.0 - self.min) * self.xscale )
            values[idx] += point.1
        }
    }
    
    public func toProbability() {
        let sum: Double = values.reduce(0, +)
        let scale: Double = 1.0 / sum
        values = values.map( {scale * $0} )
    }
    
    public func getValues() -> [Double] { values }
    public func getBinCenters() -> [Double] {
        let scale: Double = 1.0 / xscale;
        let start: Double = min + 0.5 * scale;
        return Array(0..<nbin).map( { start + Double($0) * scale } )
    }
}
