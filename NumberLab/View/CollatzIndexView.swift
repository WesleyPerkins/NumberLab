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
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(preImage, id: \.self) { odd in
                                Text(String("\(odd)"))
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Collatz Index")
        .onAppear {
            readOrCreateGraph()
        }
    }

    private func readOrCreateGraph() {
        let maxOrdinal = self.maxOrdinal
        Task.detached {
            let profiler = TimeProfiler(name: "Collatz Graph Generation")
            profiler.start(state: "Read or Create")
            do {
                let graph = try CollatzGraph.readOrCreate(maxOrdinal: N(n: maxOrdinal))
                profiler.finish()
                await MainActor.run {
                    self.graph = graph
                    self.profiler = profiler
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription; self.isLoading = false }
            }
        }
    }
}

