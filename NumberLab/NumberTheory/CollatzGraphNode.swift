import Foundation

class CollatzGraphNode: CustomStringConvertible {
    let value: Odd         // value of this node
    let next: Odd          // value of next node in Collatz map
    var prevSet: Set<Odd>  // values of currently known immediate predecessors
    
    init(value: Odd, prevSet: Set<Odd> = []) throws {
        self.value = value
        self.next = value.collatzed()
        self.prevSet = prevSet
        if !validatePrevSet() {
            throw NumberError.collatzGraphError
        }
    }
    
    var description: String {
        let list = self.prevSet.sorted()
        return "value: \(value.asInt()), next: \(next.asInt()), prevSet: \(list.map { $0.asInt() })"
    }
    
    func addPrev(_ odd: Odd) throws {
        guard odd.collatzed() == value else { throw NumberError.collatzGraphError }
        prevSet.insert(odd)
    }

    func validatePrevSet() -> Bool {
        for item in self.prevSet {
            if self.value != item.collatzed() {
                print("invalid graphNode: \(self): \(value.asInt()) is not \(item.asInt()).collatzed()")
                return false
            }
        }
        return true
    }
    
    func isRoot() -> Bool {
        next == value
    }
}

extension CollatzGraphNode: Equatable {
    static func == (lhs: CollatzGraphNode, rhs: CollatzGraphNode) -> Bool {
        lhs.value == rhs.value && lhs.prevSet == rhs.prevSet
    }
}

extension CollatzGraph: Equatable {
    static func == (lhs: CollatzGraph, rhs: CollatzGraph) -> Bool {
        lhs.maxOrdinal == rhs.maxOrdinal && lhs.map == rhs.map
    }
}

private struct CollatzGraphJSON: Codable {
    let maxOrdinal: Int
    let map: [String: [Int]]   // key = node value as string, value = prevList as [Int]
}

class CollatzGraph: CustomStringConvertible {
    let maxOrdinal: N    // map defines all nodes up to Odd(ordinal: maxOrdinal)
    var map: [Int:CollatzGraphNode] = [:]
    
    private init(maxOrdinal: N, map: [Int:CollatzGraphNode]) {
        self.maxOrdinal = maxOrdinal
        self.map = map
    }
    
    init(maxOrdinal: N) throws {
        do {
            var mapCollatz: [Int:Int] = [:]
            self.maxOrdinal = maxOrdinal
            for ordinal in 0..<maxOrdinal.asInt() {
                do {
                    var oddNumber = try Odd(ordinal: ordinal)
                    //                    print("processing: \(oddNumber)")
                    while mapCollatz[oddNumber.asInt()] == nil {
                        let oddNumberNext = oddNumber.collatzed()
                        mapCollatz.updateValue(oddNumberNext.asInt(), forKey: oddNumber.asInt())
                        oddNumber = oddNumberNext
                    }
                } catch {
                    throw NumberError.collatzGraphError
                }
            }
            self.map = try CollatzGraph.toMap(mapCollatz: mapCollatz)
        }
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
    
    static func toMap(mapCollatz: [Int:Int]) throws -> [Int:CollatzGraphNode] {
        let keys: [Int] = mapCollatz.keys.sorted()
        var work: [Int:Set<Int>] = [:]
        for key in keys {
            //            print("key: \(key)")
            let value = mapCollatz[key]!
            assert( value != key || value == 1 )
            work[value, default: Set<Int>()].insert(key)
        }
        var result: [Int:CollatzGraphNode] = [:]
        for key in keys {
            let prevSet: Set<Odd> = Set(try work[key]?.map { try Odd(n: $0) } ?? [])
            let graphNode = try CollatzGraphNode(value: Odd(n: key), prevSet: prevSet)
            //            print("graphNode: \(graphNode)")
            result.updateValue(graphNode, forKey: key)
        }
        return result
    }
    
    static let cacheDirectory = URL(fileURLWithPath: "/Volumes/ExtremePro/Caches/Collatz")
    
    static func cacheURL(maxOrdinal: N) -> URL {
        cacheDirectory.appendingPathComponent("CollatzGraph_\(maxOrdinal.asInt()).json")
    }
    
    var cacheURL: URL { CollatzGraph.cacheURL(maxOrdinal: maxOrdinal) }
    
    func serialize(to url: URL) throws {
        try FileManager.default.createDirectory(at: CollatzGraph.cacheDirectory, withIntermediateDirectories: true)
        let json = CollatzGraphJSON(
            maxOrdinal: maxOrdinal.asInt(),
            map: Dictionary(uniqueKeysWithValues: map.map { key, node in
                (String(key), node.prevSet.sorted().map { $0.asInt() })
            })
        )
        let data = try JSONEncoder().encode(json)
        try data.write(to: url)
    }
    
    static func deserialize(from url: URL) throws -> CollatzGraph {
        let data = try Data(contentsOf: url)
        let json = try JSONDecoder().decode(CollatzGraphJSON.self, from: data)
        var result: [Int:CollatzGraphNode] = [:]
        for (keyStr, prevInts) in json.map {
            guard let key = Int(keyStr) else { throw NumberError.collatzGraphError }
            let prevSet: Set<Odd> = Set(try prevInts.map { try Odd(n: $0) })
            let node = try CollatzGraphNode(value: try Odd(n: key), prevSet: prevSet)
            result[key] = node
        }
        return CollatzGraph(maxOrdinal: try N(n: json.maxOrdinal), map: result)
    }
    
    // return pre-image abs(index) steps before 1
    func preImage(index: Int) -> Set<Odd> {
        if (index >= 0) || (map[1]?.prevSet ?? []).isEmpty {
            return []
        }
        var aSet: Set<Odd> = map[1]!.prevSet
        var bSet: Set<Odd> = []
        var polar: Int = 1
        var count: Int = -1
        while count > index {
            if polar > 0 {
                bSet = []
                for o in aSet {
                    if let prevPrev = map[o.asInt()]?.prevSet {
                        for oPrev in prevPrev {
                            bSet.insert(oPrev)
                        }
                    }
                }
            } else {
                aSet = []
                for o in bSet {
                    if let prevPrev = map[o.asInt()]?.prevSet {
                        for oPrev in prevPrev {
                            aSet.insert(oPrev)
                        }
                    }
                }
            }
            polar = -polar
            count -= 1
        }
        return polar > 0 ? aSet : bSet
    }
}
    
