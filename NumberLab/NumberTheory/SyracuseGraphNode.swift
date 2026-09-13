import Foundation

class SyracuseGraphNode: Equatable, CustomStringConvertible {
    let value: Odd                  // value of this node
    let next: SyracuseGraphNode?    // next node in Syracuse map
    let height: Int                 // number of steps to get to Odd.one
    let excess: Int                 // total rinse excess to get to Odd.one
    
    init?(next: SyracuseGraphNode?, branch: Int) {
        do {
            if next == nil {
                self.value = Odd.one
                self.next = nil
                self.height = 0
                self.excess = 0
                return
            }
            if next!.value.isOne() == true {
                if branch < 3 {
                    return nil
                }
            } else {
                if branch < 1 {
                    return nil
                }
            }
            let twos = 1 << branch
            let triple = ( next!.value.asInt() *  twos ) - 1
            if ( triple % 3 ) != 0 {
                return nil
            }
            self.value = try Odd(n: triple / 3)
            self.next = next
            self.height = next!.height + 1
            self.excess = next!.excess + branch - 1
        } catch {
            return nil
        }
    }
    
    var description: String {
        "value: \(value.asInt()), next: \(next?.value.asInt() ?? 1), height: \(height), excess: \(excess)"
    }
    
    func isRoot() -> Bool {
        value.isOne()
    }
    
    static func == (lhs: SyracuseGraphNode, rhs: SyracuseGraphNode) -> Bool {
        lhs.value == rhs.value
    }
}

private struct SyracuseGraphJSON: Codable {
    let maxOrdinal: Int
    let map: [String: [Int]]   // key = node value as string, value = prevList as [Int]
}

class SyracuseGraph: Equatable, CustomStringConvertible {
    let max: Int    // map processes all nodes up to max
    var map: [Int:SyracuseGraphNode] = [:]
    let root: SyracuseGraphNode = SyracuseGraphNode(next: nil, branch: 0)!
    
    private init(max: Int, map: [Int:SyracuseGraphNode]) {
        self.max = max
        self.map = map
    }
    
    init(max: Int) throws {
        self.max = max
        let queue = Queue<SyracuseGraphNode>()
        queue.add( self.root )
        map.updateValue(self.root, forKey: 1)
        repeat {
            let next = queue.remove()!
            for branch in 1..<32 {   // 32 is a stop-gap
                if let prev = SyracuseGraphNode(next: next, branch: branch) {
                    if prev.value.asInt() > self.max {
                        break
                    }
//                    print("\(prev.value) height \(prev.height) precedes \(next.value) on branch \(branch)")
                    queue.add(prev)
                    map.updateValue(prev, forKey: prev.value.asInt())
                    if map.count % 1000 == 0 {
//                        print("processed \(map.count) items, next: \(next)")
                        print("processed \(map.count) items, queue size: \(queue.count())")
                    }
                }
            }
        } while !queue.isEmpty()
        print("ready to plot \(map.count) items")
    }
    
    var description: String {
        var result: String = ""
        let keys: [Int] = map.keys.sorted()
        for key in keys {
            let value = map[key]!
            result += String("\n\(key): \(value)")
        }
        return result
    }

    func heightBounds() -> (min: Int, max: Int) {
        let heights = map.values.map { $0.height }
        return (min: heights.min()!, max: heights.max()!)
    }

    func excessBounds() -> (min: Int, max: Int) {
        let excesses = map.values.map { $0.excess }
        return (min: excesses.min()!, max: excesses.max()!)
    }

    static let cacheDirectory = URL(fileURLWithPath: "/Volumes/ExtremePro/Caches/Syracuse")
    
    static func cacheURL(max: Int) -> URL {
        cacheDirectory.appendingPathComponent("SyracuseGraph_\(max).json")
    }
    
    var cacheURL: URL { SyracuseGraph.cacheURL(max: max) }

    static func == (lhs: SyracuseGraph, rhs: SyracuseGraph) -> Bool {
        lhs.max == rhs.max && lhs.map == rhs.map
    }
}
    
//    func serialize(to url: URL) throws {
//        try FileManager.default.createDirectory(at: SyracuseGraph.cacheDirectory, withIntermediateDirectories: true)
//        let sortedKeys = map.keys.sorted()
//        var lines: [String] = ["{", "  \"max\":\(max),", "  \"map\":{"]
//        for (i, key) in sortedKeys.enumerated() {
//            let prevList = map[key]!.prevSet.sorted().map { String($0.asInt()) }.joined(separator: ",")
//            let comma = i < sortedKeys.count - 1 ? "," : ""
//            lines.append("    \"\(key)\":[\(prevList)]\(comma)")
//        }
//        lines.append("  }")
//        lines.append("}")
//        try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
//    }
    
    //    static func readOrCreate(maxOrdinal: N) throws -> SyracuseGraph {
    //        let url = cacheURL(maxOrdinal: maxOrdinal)
    //        if FileManager.default.fileExists(atPath: url.path) {
    //            if let graph = try? deserialize(from: url) {
    //                return graph
    //            }
    //        }
    //        let graph = try SyracuseGraph(maxOrdinal: maxOrdinal)
    //        try? graph.serialize(to: url)
    //        return graph
    //    }

//    static func deserialize(from url: URL) throws -> SyracuseGraph {
//        let data = try Data(contentsOf: url)
//        let json = try JSONDecoder().decode(SyracuseGraphJSON.self, from: data)
//        var result: [Int:SyracuseGraphNode] = [:]
//        for (keyStr, prevInts) in json.map {
//            guard let key = Int(keyStr) else { throw NumberError.syracuseGraphError }
//            let prevSet: Set<Odd> = Set(try prevInts.map { try Odd(n: $0) })
//            let node = try SyracuseGraphNode(value: try Odd(n: key), prevSet: prevSet)
//            result[key] = node
//        }
//        return SyracuseGraph(maxOrdinal: try N(n: json.maxOrdinal), map: result)
//    }
