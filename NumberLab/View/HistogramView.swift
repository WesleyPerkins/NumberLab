import SwiftUI

struct HistogramView: View {
    let nbit: Int
    
    var body: some View {
        let histogram: HistogramModel = Odd.collatzProbability(ntrial: 10000, nbit: nbit, nbin: 32)
        let labels: [String] = histogram.getBinCenters().map( {"\(Int($0.rounded()))"} )
        let data: [Double] = histogram.getValues()
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(data.indices, id: \.self) { index in
                let maxValue: Double = data.max()!
                HistogramBar(value: data[index], maxValue: maxValue, label: labels[index])
            }
        }
        .padding()
    }
}

struct HistogramBar: View {
    var value: Double
    var maxValue: Double
    var label: String
    
    var body: some View {
        VStack {
            Spacer()
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue)
                .frame(height: CGFloat(value / maxValue) * 200)
//            withAnimation(.easeIn(duration: 035)) { }
//                .animation(.easeInOut(duration: 0.5))
//            Text(label)
//                .font(.caption)
        }
    }
}

