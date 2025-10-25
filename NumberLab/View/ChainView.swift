import SwiftUI

struct ChainView: View {
    let nchain: Int
    let nbit: Int
    
    @State private var chains: [[Int]] = []
    @State private var isLoading: Bool = true
    
    init(nchain: Int, nbit: Int = 30) {
        self.nchain = nchain
        self.nbit = nbit
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Collatz chains...")
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(chains.indices, id: \.self) { index in
                            ChainRow(chainNumber: index + 1, chain: chains[index])
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Collatz Chains"/* (\(nbit)-bit)*/)
        .onAppear {
            generateChains()
        }
    }
    
    private func generateChains() {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Collatz Chain Generation")
            profiler.start(state: "Initialization")
            
            var results: [[Int]] = []
            
            profiler.start(state: "Generating Chains")
            for ordinal in 0..<nchain {
                do {
//                    let oddNumber = try Odd(nbit: nbit)
                    let oddNumber = try Odd(ordinal: ordinal)
                    let chain = oddNumber.collatzChain()
                    let intChain = chain.compactMap { try? $0.asInt() }
                    results.append(intChain)
                } catch {
                    print("Error generating chain: \(error)")
                }
            }
            
            profiler.start(state: "Finalization")
            profiler.finish()
            
            let report = profiler.description
            print(report)
            
            DispatchQueue.main.async {
                self.chains = results
                self.isLoading = false
            }
        }
    }
}

struct ChainRow: View {
    let chainNumber: Int
    let chain: [Int]
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(chainNumber):")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            Text(chainString)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
    
    private var chainString: String {
        chain.map { String($0) }.joined(separator: " → ")
    }
}

#Preview {
    NavigationView {
        ChainView(nchain: 10, nbit: 20)
    }
}
