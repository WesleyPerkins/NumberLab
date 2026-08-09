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
                ProgressView("Generating Collatz halo...")
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
        .navigationTitle("Collatz Halo")
        .onAppear {
            generateHalo()
        }
    }

    private func generateHalo() {
        DebugUtl.needMoreLogic()
//        DispatchQueue.global(qos: .userInitiated).async {
//            let profiler = TimeProfiler(name: "Collatz Halo Generation")
//            profiler.start(state: "Generating Halo")
//
//            let halo = CollatzHalo()
//            let limit: Odd = try! Odd(ordinal: maxCount)
//            while halo.maxSolid < limit {
//                halo.step()
//            }
//
//            profiler.start(state: "Rendering Image")
//            
////            let matrix = PixelMatrix(type: .gray, nrow: Self.imageWidth, ncol: Self.imageHeight)
//            
//            let matrix = SparseMatrix(type: .gray, nrow: Self.imageWidth, ncol: Self.imageHeight)
////            matrix.pixels = [UInt8](repeating: 255, count: matrix.pixels.count)
//            let baseOrdinal = halo.maxSolid.asOrdinal()
//            let total = Self.imageWidth * Self.imageHeight
//            for o in halo.haloSet {
//                let offset = o.asOrdinal() - baseOrdinal
//                if offset >= 0 && offset < total {
//                    matrix.set(row: offset / Self.imageWidth, col: offset % Self.imageWidth, rawPixel: [0])
//                }
//            }
//            let image = CGImage.create(pixelMatrix: matrix)?.swiftUIImage()
//
//            profiler.finish()
//            print(profiler.description)
//
//            DispatchQueue.main.async {
//                self.summary = "\(halo)"
//                self.haloImage = image
//                self.isLoading = false
//            }
    }
}
