import SwiftUI

struct CollatzGraphView: View {
    let maxOrdinal: Int
    
    @State private var graph: CollatzGraph? = nil
    @State private var isLoading: Bool = true
    @State private var profiler: TimeProfiler? = nil
    @State private var errorMessage: String? = nil

    init(nchain: Int) {
        self.maxOrdinal = nchain
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Collatz graph...")
                    .padding()
            } else if let message = errorMessage {
                Text(message).foregroundStyle(.red).padding()
            } else {
                if let report = profiler?.description {
                    Text(report).font(.title)
                }
            }
        }
        .navigationTitle("Collatz Chains")
        .onAppear {
            readOrCreateGraph()
        }
    }

    private func readOrCreateGraph() {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Collatz Graph Generation")
            profiler.start(state: "Read or Create")
            do {
                let graph = try CollatzGraph.readOrCreate(maxOrdinal: N(n: maxOrdinal))
                profiler.finish()
                DispatchQueue.main.async {
                    self.graph = graph
                    self.profiler = profiler
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
            }
        }
    }
}

