import SwiftUI

struct CollatzGraphView: View {
    let maxOrdinal: Int
    
    @State private var graph: CollatzGraph? = nil
    @State private var isLoading: Bool = true
    @State private var profiler: TimeProfiler? = nil
    @State private var errorMessage: String? = nil
    @State private var roundTripOK: Bool? = nil

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
                if let ok = roundTripOK {
                    Text(ok ? "Round-trip: OK" : "Round-trip: MISMATCH")
                        .foregroundStyle(ok ? .green : .red)
                }
                if let report = profiler?.description {
                    Text(report).font(.title)
                }
            }
        }
        .navigationTitle("Collatz Chains")
        .onAppear {
//            generateGraph()
            readGraph(maxOrdinal: maxOrdinal)
        }
    }

    private func generateGraph() {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Collatz Graph Generation")
            var graph: CollatzGraph
            var graphRT: CollatzGraph

            profiler.start(state: "Generating Graph")
            do {
                graph = try CollatzGraph( maxOrdinal: try N(n: maxOrdinal) )
            } catch {
                DispatchQueue.main.async { errorMessage = error.localizedDescription; isLoading = false }
                return
            }

            profiler.start(state: "Save to Disk")
            do {
                try graph.serialize(to: graph.cacheURL)
            } catch {
                DispatchQueue.main.async { errorMessage = error.localizedDescription; isLoading = false }
                return
            }

            profiler.start(state: "Read from Disk")
            do {
                try graphRT = CollatzGraph.deserialize(from: graph.cacheURL)
            } catch {
                DispatchQueue.main.async { errorMessage = error.localizedDescription; isLoading = false }
                return
            }

            let ok = graph == graphRT
            profiler.finish()

            DispatchQueue.main.async {
                self.graph = graph
                self.roundTripOK = ok
                self.profiler = profiler
                self.isLoading = false
            }
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

