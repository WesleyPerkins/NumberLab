import SwiftUI

struct HaloView: View {
    let maxCount: Int

    @State private var halos: [CollatzHalo] = []
    @State private var isLoading: Bool = true

    init(maxCount: Int) {
        self.maxCount = maxCount
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Collatz halos...")
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(halos.indices, id: \.self) { index in
                            Text( String("\(halos[index])") )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Collatz Halo")
        .onAppear {
            generateHalos()
        }
    }

    private func generateHalos() {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Collatz Halo Generation")
            profiler.start(state: "Initialization")

            var results: [CollatzHalo] = []

            profiler.start(state: "Generating Halos")
            var count: Int = 1000
            let halo: CollatzHalo = CollatzHalo()
            while count <= maxCount {
                do {
                    let limit: Odd = try Odd(ordinal: count)
                    while halo.maxSolid < limit {
                        halo.step()
                    }
                    results.append(CollatzHalo.copy(halo))
                } catch {
                    print("Error generating halo: \(error)")
                }
                count *= 10
            }

            profiler.start(state: "Finalization")
            profiler.finish()

            let report = profiler.description
            print(report)

            DispatchQueue.main.async {
                self.halos = results
                self.isLoading = false
            }
        }
    }
}

struct HaloRow: View {
    let haloNumber: Int
    let halo: [Odd]

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(haloNumber):")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)

            Text(haloString)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private var haloString: String {
        halo.map { $0.description }.joined(separator: " → ")
    }
}
