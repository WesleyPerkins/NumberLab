import SwiftUI
import Graphics2D

struct HaloView: View {
    let maxCount: Int

    @State private var haloImage: Image?
    @State private var summary: String = ""
    @State private var isLoading: Bool = true

    private static let pixelCoord = PixelCoord(width: 1024, height: 800, density: 1)

    init(maxCount: Int) {
        self.maxCount = maxCount
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Syracuse halo...")
                    .padding()
            } else {
                Text(summary)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.bottom, 4)
                if let haloImage {
                    haloImage
                        .interpolation(.none)
//                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: CGFloat(Self.pixelCoord.width), maxHeight: CGFloat(Self.pixelCoord.height))
                }
                Button("Step") {
                    print("step")
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.85, green: 0.93, blue: 1.0))
        .navigationTitle("Syracuse Halo")
        .onAppear {
            generateHalo()
        }
    }

    private func generateHalo() {
        DebugUtl.needMoreLogic()
    }
}
