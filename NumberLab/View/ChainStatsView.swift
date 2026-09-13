import SwiftUI
import Graphics2D

struct ChainStatsView: View {
    let nchain: Int
    let nbit: Int
    
//    @State private var chains: [ ( [Odd], [Int] ) ] = []
    @State private var map: [ Odd : (Int, Int) ] = [:]
    @State private var isLoading: Bool = true
    
    init(nchain: Int, nbit: Int = 30) {
        self.nchain = nchain
        self.nbit = nbit
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Syracuse chain stats...")
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    let maxNstep: Int = map.values.map { $0.0 }.max() ?? 0
                    let maxSumPow2: Int = map.values.map { $0.1 }.max() ?? 0
                    let uniqueValueCount = Set(map.values.map { "\($0.0),\($0.1)" }).count
                    Text("maxNstep: \(maxNstep) maxSumPow2: \(maxSumPow2) map key count: \(map.keys.count) value count: \(uniqueValueCount) ")
//                    ForEach(chains.indices, id: \.self) { index in
//                        ChainRow(chainNumber: index + 1, chain: chains[index])
//                    }
                    let lattice = makeLattice(maxX: maxSumPow2, maxY: maxNstep)
                    Lattice2DView(
                        lattice: lattice,
                        pointColor: { _ in .blue }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding()
            }
        }
        .navigationTitle("Syracuse Chains")
        .onAppear {
            generateChainStats()
        }
    }
    
    private func generateChainStats() {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Syracuse Chain Stats Generation")
            profiler.start(state: "Initialization")
            
            var results: [ Odd : (Int, Int) ] = [:]
            
            profiler.start(state: "Generating Chains")
            for ordinal in 0..<nchain {
                do {
                    let oddNumber = try Odd(ordinal: ordinal)
                    let chain = oddNumber.syracuseChain()
                    let coord = ChainStatsView.chainCoord(chain)
                    results[oddNumber] = coord
                } catch {
                    print("Error generating chain: \(error)")
                }
            }
            
            profiler.start(state: "Finalization")
            profiler.finish()
            
            let report = profiler.description
            print(report)
            
            DispatchQueue.main.async {
                self.map = results
                self.isLoading = false
            }
        }
    }

    static func chainCoord(_ chain: ( [Odd], [Int] )) -> (Int, Int) {
        (chain.1.count, chain.1.reduce(0, +))
    }

    private func makeLattice(maxX: Int, maxY: Int) -> Lattice2D<Void> {
        let lattice = Lattice2D<Void>(maxX: maxX, maxY: maxY)
        for coord in map.values {
            lattice.set(x: coord.1, y: coord.0, value: ())
        }
        return lattice
    }

}
