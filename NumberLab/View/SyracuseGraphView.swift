import SwiftUI
#if os(macOS)
import AppKit
#endif

private struct SyracusePointKey: Hashable {
    let excess: Int
    let height: Int
}

struct SyracuseGraphView: View {
    let max: Int

    @State private var graph: SyracuseGraph? = nil
    @State private var isLoading: Bool = true
    @State private var profiler: TimeProfiler? = nil
    @State private var errorMessage: String? = nil
    @State private var zoomScale: CGFloat = 1.0
    @State private var viewOriginExcess: CGFloat = 0
    @State private var viewOriginHeight: CGFloat = 0
    @State private var dragStartPoint: CGPoint? = nil
    @State private var dragRect: CGRect? = nil
    @State private var isPanGesture: Bool = false
    @State private var panStartOriginExcess: CGFloat = 0
    @State private var panStartOriginHeight: CGFloat = 0
    @State private var pointIndex: [SyracusePointKey: [SyracuseGraphNode]] = [:]
    @State private var hoverLocation: CGPoint? = nil
    @State private var hoverNodes: [SyracuseGraphNode] = []

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
                plotGraph()
            }
        }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Syracuse Chains")
            .onAppear {
                createGraph(max: max)
            }
    }

    @ViewBuilder
    private func plotGraph() -> some View {
        if let graph = graph {
            let maxHeight = Swift.max(graph.heightBounds().max, 1)
            let maxExcess = Swift.max(graph.excessBounds().max, 1)

            GeometryReader { geo in
                let padding: CGFloat = 36
                let plotWidth = Swift.max(geo.size.width - 2 * padding, 1)
                let plotHeight = Swift.max(geo.size.height - 2 * padding, 1)
                let scaleX = (plotWidth / CGFloat(maxExcess)) * zoomScale
                let scaleY = (plotHeight / CGFloat(maxHeight)) * zoomScale
                let originX = padding
                let originY = geo.size.height - padding
                let plotRect = CGRect(x: originX, y: originY - plotHeight, width: plotWidth, height: plotHeight)
                let visibleExcessRange = CGFloat(maxExcess) / zoomScale
                let visibleHeightRange = CGFloat(maxHeight) / zoomScale
                let leftExcess = Int(viewOriginExcess.rounded())
                let rightExcess = Int((viewOriginExcess + visibleExcessRange).rounded())
                let bottomHeight = Int(viewOriginHeight.rounded())
                let topHeight = Int((viewOriginHeight + visibleHeightRange).rounded())

                ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    var axes = Path()
                    axes.move(to: CGPoint(x: originX, y: originY))
                    axes.addLine(to: CGPoint(x: originX + plotWidth, y: originY))
                    axes.move(to: CGPoint(x: originX, y: originY))
                    axes.addLine(to: CGPoint(x: originX, y: originY - plotHeight))
                    context.stroke(axes, with: .color(.primary), lineWidth: 1)

                    let dotRadius = 1.0 * zoomScale
                    for node in graph.map.values {
                        let x = originX + (CGFloat(node.excess) - viewOriginExcess) * scaleX
                        let y = originY - (CGFloat(node.height) - viewOriginHeight) * scaleY
                        let dot = Path(ellipseIn: CGRect(x: x - dotRadius, y: y - dotRadius, width: 2 * dotRadius, height: 2 * dotRadius))
                        context.fill(dot, with: .color(Color(red: 0.55, green: 0.0, blue: 0.0)))
                    }

                    // x-axis annotation: label + endpoint tick values
                    context.draw(Text("\(leftExcess)").font(.caption2), at: CGPoint(x: originX, y: originY + 4), anchor: .top)
                    context.draw(Text("\(rightExcess)").font(.caption2), at: CGPoint(x: originX + plotWidth, y: originY + 4), anchor: .top)
                    context.draw(Text("excess").font(.caption), at: CGPoint(x: originX + plotWidth / 2, y: originY + 16), anchor: .top)

                    // y-axis annotation: endpoint tick value + rotated label
                    context.draw(Text("\(bottomHeight)").font(.caption2), at: CGPoint(x: originX - 4, y: originY), anchor: .trailing)
                    context.draw(Text("\(topHeight)").font(.caption2), at: CGPoint(x: originX - 4, y: originY - plotHeight), anchor: .trailing)
                    context.drawLayer { layer in
                        let labelPoint = CGPoint(x: originX - 16, y: originY - plotHeight / 2)
                        layer.translateBy(x: labelPoint.x, y: labelPoint.y)
                        layer.rotate(by: .degrees(-90))
                        layer.draw(Text("height").font(.caption), at: .zero, anchor: .bottom)
                    }

                    if let dragRect = dragRect {
                        let marquee = Path(dragRect)
                        context.stroke(marquee, with: .color(.gray), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                }
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 2, coordinateSpace: .local)
                        .onChanged { value in
                            if dragStartPoint == nil {
                                dragStartPoint = clamp(value.startLocation, to: plotRect)
                                isPanGesture = Self.isOptionKeyDown
                                if isPanGesture {
                                    panStartOriginExcess = viewOriginExcess
                                    panStartOriginHeight = viewOriginHeight
                                }
                            }
                            guard let start = dragStartPoint else { return }
                            let current = clamp(value.location, to: plotRect)
                            if isPanGesture {
                                let dx = current.x - start.x
                                let dy = current.y - start.y
                                viewOriginExcess = Swift.max(0, panStartOriginExcess - dx / scaleX)
                                viewOriginHeight = Swift.max(0, panStartOriginHeight + dy / scaleY)
                                dragRect = nil
                            } else {
                                dragRect = aspectRect(from: start, to: current, aspect: plotWidth / plotHeight)
                            }
                        }
                        .onEnded { _ in
                            if !isPanGesture, let rect = dragRect, rect.width > 0, rect.height > 0 {
                                applyDragZoom(rect: rect, originX: originX, originY: originY, scaleX: scaleX, scaleY: scaleY, maxExcess: maxExcess)
                            }
                            dragStartPoint = nil
                            dragRect = nil
                            isPanGesture = false
                        }
                )
                .onContinuousHover(coordinateSpace: .local) { phase in
                    switch phase {
                    case .active(let location):
                        guard plotRect.contains(location) else {
                            hoverLocation = nil
                            hoverNodes = []
                            return
                        }
                        let dataExcess = viewOriginExcess + (location.x - originX) / scaleX
                        let dataHeight = viewOriginHeight + (originY - location.y) / scaleY
                        hoverLocation = location
                        hoverNodes = nearestNodes(toExcess: dataExcess, height: dataHeight, scaleX: scaleX, scaleY: scaleY)
                    case .ended:
                        hoverLocation = nil
                        hoverNodes = []
                    }
                }

                if let hoverLocation = hoverLocation, !hoverNodes.isEmpty {
                    hoverPopup(nodes: hoverNodes)
                        .position(
                            x: Swift.min(Swift.max(hoverLocation.x + 60, 60), geo.size.width - 60),
                            y: Swift.max(hoverLocation.y - 40, 24)
                        )
                }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(zoomKeyCommands)
        } else {
            Text("your graph goes here").font(.title)
        }
    }

    // Hidden buttons so Command+/Command-/Command 0 are available as keyboard shortcuts.
    private var zoomKeyCommands: some View {
        Group {
            Button("Zoom In") { zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
            Button("Zoom Out") { zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
            Button("Actual Size") { zoomReset() }
                .keyboardShortcut("0", modifiers: .command)
        }
        .opacity(0)
        .frame(width: 0, height: 0)
    }

    private func zoomIn() {
        zoomScale = Swift.min(zoomScale * 1.25, 50)
    }

    private func zoomOut() {
        zoomScale = Swift.max(zoomScale / 1.25, 0.1)
    }

    private func zoomReset() {
        zoomScale = 1.0
        viewOriginExcess = 0
        viewOriginHeight = 0
    }

    @ViewBuilder
    private func hoverPopup(nodes: [SyracuseGraphNode]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(nodes.indices, id: \.self) { index in
                Text(nodes[index].description).font(.caption2)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        .fixedSize()
    }

    // Finds the grid point (integer excess/height) nearest to the given data-space location
    // and returns every node plotted there (several distinct values can share one point),
    // searching outward through pointIndex a ring at a time so it stays fast even for graphs
    // with hundreds of thousands of nodes.
    private func nearestNodes(toExcess excess: CGFloat, height: CGFloat, scaleX: CGFloat, scaleY: CGFloat) -> [SyracuseGraphNode] {
        let centerExcess = Int(excess.rounded())
        let centerHeight = Int(height.rounded())
        var best: (distSq: CGFloat, key: SyracusePointKey, nodes: [SyracuseGraphNode])? = nil
        let maxRadius = 64
        var radius = 0
        var extraRingsRemaining = 1
        while radius <= maxRadius {
            for de in -radius...radius {
                for dh in -radius...radius {
                    if radius > 0 && abs(de) != radius && abs(dh) != radius { continue }
                    let key = SyracusePointKey(excess: centerExcess + de, height: centerHeight + dh)
                    guard let nodes = pointIndex[key] else { continue }
                    let dx = (CGFloat(key.excess) - excess) * scaleX
                    let dy = (CGFloat(key.height) - height) * scaleY
                    let distSq = dx * dx + dy * dy
                    if best == nil || distSq < best!.distSq {
                        best = (distSq, key, nodes)
                    }
                }
            }
            // Once we have a hit, scan one extra ring: scaleX/scaleY can differ, so a
            // pixel-closer point can still land in the next Chebyshev ring out.
            if best != nil {
                if extraRingsRemaining == 0 { break }
                extraRingsRemaining -= 1
            }
            radius += 1
        }
        guard let best = best else { return [] }
        // Suppress the popup once the cursor drifts more than half a data unit away
        // from the nearest point on either axis.
        guard abs(CGFloat(best.key.excess) - excess) <= 0.5,
              abs(CGFloat(best.key.height) - height) <= 0.5 else {
            return []
        }
        return best.nodes
    }

    // Option-drag pans instead of drawing the zoom marquee; only meaningful on macOS,
    // where a physical modifier key is available during a mouse drag.
    private static var isOptionKeyDown: Bool {
        #if os(macOS)
        NSEvent.modifierFlags.contains(.option)
        #else
        false
        #endif
    }

    private func clamp(_ point: CGPoint, to rect: CGRect) -> CGPoint {
        CGPoint(
            x: Swift.min(Swift.max(point.x, rect.minX), rect.maxX),
            y: Swift.min(Swift.max(point.y, rect.minY), rect.maxY)
        )
    }

    // Builds a rectangle anchored at `start`, extending toward `end`, whose width:height
    // ratio matches `aspect` (the plot's own aspect ratio) regardless of the raw drag shape.
    private func aspectRect(from start: CGPoint, to end: CGPoint, aspect: CGFloat) -> CGRect {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let rawWidth = abs(dx)
        let rawHeight = abs(dy)
        var width = rawWidth
        var height = rawHeight
        if rawHeight == 0 || (rawWidth / rawHeight) > aspect {
            height = rawWidth / aspect
        } else {
            width = rawHeight * aspect
        }
        let signedEnd = CGPoint(
            x: start.x + (dx >= 0 ? width : -width),
            y: start.y + (dy >= 0 ? height : -height)
        )
        return CGRect(
            x: Swift.min(start.x, signedEnd.x),
            y: Swift.min(start.y, signedEnd.y),
            width: width,
            height: height
        )
    }

    // Makes the dragged-out rectangle the new full view: its lower-left corner (in data
    // space) becomes the new (0, 0) reference point, and its size determines the new zoomScale.
    private func applyDragZoom(rect: CGRect, originX: CGFloat, originY: CGFloat, scaleX: CGFloat, scaleY: CGFloat, maxExcess: Int) {
        guard scaleX > 0, rect.width > 0 else { return }
        let newOriginExcess = viewOriginExcess + (rect.minX - originX) / scaleX
        let newOriginHeight = viewOriginHeight + (originY - rect.maxY) / scaleY
        let newVisibleExcessRange = rect.width / scaleX
        let newZoomScale = CGFloat(maxExcess) / newVisibleExcessRange
        viewOriginExcess = newOriginExcess
        viewOriginHeight = newOriginHeight
        zoomScale = Swift.max(newZoomScale, 0.01)
    }

    private func createGraph(max: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            let profiler = TimeProfiler(name: "Syracuse Graph Generation")
            profiler.start(state: "Create")
            do {
                let graph = try SyracuseGraph(max: max)
                profiler.finish()
                print(profiler.description)
                var index: [SyracusePointKey: [SyracuseGraphNode]] = [:]
                for node in graph.map.values {
                    let key = SyracusePointKey(excess: node.excess, height: node.height)
                    index[key, default: []].append(node)
                }
                DispatchQueue.main.async {
                    self.graph = graph
                    self.pointIndex = index
                    self.profiler = profiler
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
            }
        }
    }
}
