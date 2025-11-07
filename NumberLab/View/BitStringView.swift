import SwiftUI

struct BitStringView: View {
    let maxbit: Int

    @State private var chains: [[String]] = []
    @State private var isLoading: Bool = true
    
    init(maxbit: Int = 32) {
        self.maxbit = maxbit
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
                            ChainSeq(chain: chains[index])
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
            var results: [[String]] = []
            for power in 1...maxbit {
                let n = (1 << power) - 1
                do {
                    let oddNumber = try Odd(n: n)
                    let chain = oddNumber.collatzChain()
                    let bitStringChain = chain.compactMap { $0.description }
                    results.append(bitStringChain)
                } catch {
                    print("Error generating chain: \(error)")
                }
            }
            DispatchQueue.main.async {
                self.chains = results
                self.isLoading = false
            }
        }
    }
}

struct ChainSeq: View {
    let chain: [String]
    
    var body: some View {
        VStack {
            ForEach (chain.indices, id: \.self) { index in
                Text("\(chain[index])")
            }
            Text("")
        }
            .font(.system(.body, design: .monospaced))
    }
}
