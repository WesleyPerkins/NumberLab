import SwiftUI

struct CollatzIndexView: View {
    let maxOrdinal: Int
    let index: Int

    @State private var graph: CollatzGraph? = nil
    @State private var isLoading: Bool = true
    @State private var profiler: TimeProfiler? = nil
    @State private var errorMessage: String? = nil

    init(nchain: Int, index: Int) {
        self.maxOrdinal = nchain
        self.index = index
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Collatz graph...")
                    .padding()
            } else if let message = errorMessage {
                Text(message).foregroundStyle(.red).padding()
            } else if let graph {
                let preImage = graph.preImage(index: index)
                if preImage.isEmpty {
                    Text("No pre-image found for index \(index)")
                } else {
                    Text("Pre-image has \(preImage.count) elements")
                }
            }
        }
        .navigationTitle("Collatz Index")
        .onAppear {
            readGraph(maxOrdinal: maxOrdinal)
        }
    }

    private func readGraph(maxOrdinal: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Collatz Graph Generation")
            var graph: CollatzGraph

            profiler.start(state: "Read from Disk")
            do {
                try graph = CollatzGraph.deserialize(from: CollatzGraph.cacheURL(maxOrdinal: N(ordinal: maxOrdinal - 1)))
            } catch {
                DispatchQueue.main.async { errorMessage = error.localizedDescription; isLoading = false }
                return
            }
            profiler.finish()

            DispatchQueue.main.async {
                self.graph = graph
                self.profiler = profiler
                self.isLoading = false
            }
        }
    }
}

