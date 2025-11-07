import SwiftUI

struct HistogramView: View {
    let nbit: Int
    
    @State private var histogram: HistogramModel?
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating histogram...")
                    .padding()
            } else if let histogram = histogram {
                GeometryReader { geometry in
                    let labels: [String] = histogram.getBinCenters().map( {"\(Int($0.rounded()))"} )
                    let data: [Double] = histogram.getValues()
                    let maxValue: Double = data.max()!
                    let minX: Double = histogram.getBinCenters().first ?? 0
                    let maxX: Double = histogram.getBinCenters().last ?? 0
                    
                    // Calculate responsive dimensions
                    let availableHeight = geometry.size.height - 150 // Reserve space for labels and axes
                    let chartHeight = max(150, availableHeight * 0.95) // At least 150px, or 60% of available height
                    
                    VStack(alignment: .leading, spacing: 0) {
                        // Chart area with Y-axis
                        HStack(alignment: .bottom, spacing: 0) {
                            // Y-axis line
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(width: 3, height: chartHeight)
                            }
                            
                            // Bars
                            HStack(alignment: .bottom, spacing: 3) {
                                ForEach(data.indices, id: \.self) { index in
                                    HistogramBar(value: data[index], maxValue: maxValue, label: labels[index], chartHeight: chartHeight)
                                }
                            }
                            .padding(.leading, 4)
                        }
                        
                        // X-axis
                        HStack(alignment: .top, spacing: 0) {
                            // Y-axis offset
                            Rectangle()
                                .fill(Color.clear)
                                .frame(width: 3, height: 3)
                            
                            Rectangle()
                                .fill(Color.primary)
                                .frame(height: 3)
                                .padding(.leading, 4)
                        }
                        
                        // X-axis labels
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(String(format: "%.0f", minX))
                                    .font(.system(.title2, design: .monospaced))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(String(format: "%.0f", maxX))
                                    .font(.system(.title2, design: .monospaced))
                                    .foregroundColor(.primary)
                            }
                            .padding(.leading, 7)
                            .padding(.trailing, 4)
                        }
                        .padding(.top, 4)
                        
                        // X-axis title (centered)
                        HStack {
                            Spacer()
                            Text("Collatz Chain Length")
                                .font(.system(.body, design: .default).bold())
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            generateHistogram()
        }
    }
    
    private func generateHistogram() {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Collatz Histogram Generation")
            profiler.start(state: "Initialization")
            
            profiler.start(state: "Computing Histogram")
            let result = Odd.collatzProbability(ntrial: 10000, nbit: nbit, nbin: 32)
            
            profiler.start(state: "Finalization")
            profiler.finish()
            
            let report = profiler.description
            print(report)
            
            DispatchQueue.main.async {
                self.histogram = result
                self.isLoading = false
            }
        }
    }
}

struct HistogramBar: View {
    var value: Double
    var maxValue: Double
    var label: String
    var chartHeight: CGFloat = 150
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hover tooltip positioned just above the bar
            if isHovering {
                Text(String(format: "%.4f", value))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(4)
                    .shadow(radius: 2)
                    .fixedSize()
                    .offset(y: -4)
            }
            
            RoundedRectangle(cornerRadius: 2)
                .fill(isHovering ? Color.blue.opacity(0.8) : Color.blue)
                .frame(height: CGFloat(value / maxValue) * chartHeight)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

