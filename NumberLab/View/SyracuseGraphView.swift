import SwiftUI

struct SyracuseGraphView: View {
    let max: Int
    
    @State private var graph: SyracuseGraph? = nil
    @State private var isLoading: Bool = true
    @State private var profiler: TimeProfiler? = nil
    @State private var errorMessage: String? = nil

    init(nchain: Int) {
        self.max = nchain
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Syracuse graph...")
                    .padding()
            } else if let message = errorMessage {
                Text(message).foregroundStyle(.red).padding()
            } else {
                if let report = profiler?.description {
                    Text(report).font(.title)
                }
            }
        }
            .navigationTitle("Syracuse Chains")
            .onAppear {
                createGraph(max: max)
            }
    }

    private func createGraph(max: Int) {
            DispatchQueue.global(qos: .userInitiated).async {
                let profiler = TimeProfiler(name: "Syracuse Graph Generation")
                profiler.start(state: "Create")
                do {
                    let graph = try SyracuseGraph(max: max)
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
    
    //    private func readOrCreateGraph() {
    //        DispatchQueue.global(qos: .userInitiated).async {
    //            let profiler = TimeProfiler(name: "Syracuse Graph Generation")
    //            profiler.start(state: "Read or Create")
    //            do {
    //                let graph = try SyracuseGraph.readOrCreate(maxOrdinal: N(n: maxOrdinal))
    //                profiler.finish()
    //                DispatchQueue.main.async {
    //                    self.graph = graph
    //                    self.profiler = profiler
    //                    self.isLoading = false
    //                }
    //            } catch {
    //                DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
    //            }
    //        }
    //    }
}

