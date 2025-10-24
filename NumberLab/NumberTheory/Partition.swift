import Foundation

struct Partition: Validity, Hashable, Equatable, CustomStringConvertible {
    let globs: [Glob]
    let n: Int
    
    static let congruence_5_1_4: Residues = Residues(n: 5, values: [1,4])
    static let congruence_2_1: Residues = Residues(n: 2, values: [1])

    static func == (lhs: Partition, rhs: Partition) -> Bool {
        if lhs.globs.count != rhs.globs.count { return false }
        for idx in 0..<lhs.globs.count {
            if !(lhs.globs[idx] == rhs.globs[idx]) { return false }
        }
        return true
    }
    
    static func fullPartitionList(n: Int, verbose: Bool = false) -> [Partition] {
        var result: [Partition] = []
        for maxHeight in 1...n {
            let subList: [Partition] = Sublist.lookUp(SublistSpec(n: n, maxHeight: maxHeight, minDiff: nil, atomFilter: nil)).list
            result += subList
            if verbose { print("finished maxHeight: \(maxHeight)") }
        }
        return result.sorted(by: { $0.precedes($1) } )
    }
    
    static func fullPartitionList(n: Int, atomFilter: AtomFilter, verbose: Bool = false) -> [Partition] {
        var result: [Partition] = []
        for maxHeight in 1...n {
            if atomFilter.accept(maxHeight) {
                let subList: [Partition] = Sublist.lookUp(SublistSpec(n: n, maxHeight: maxHeight, minDiff: nil, atomFilter: atomFilter)).list
                result += subList
                if verbose { print("finished maxHeight: \(maxHeight)") }
            }
        }
        return result
    }
    
    static func fullPartitionList(n: Int, minDiff: Int?) -> [Partition] {
        var result: [Partition] = []
        for maxHeight in 1...n {
            let subList: [Partition] = Sublist.lookUp(SublistSpec(n: n, maxHeight: maxHeight, minDiff: minDiff, atomFilter: nil)).list
            for partition in subList {
                result.append( partition )
            }
        }
        return result
    }
    
    static func fullPartitionCount(n: Int) -> Int {
        var result: Int = 0
        for maxHeight in 1...n {
            result += Sublist.lookUpCount(SublistSpec(n: n, maxHeight: maxHeight, minDiff: nil, atomFilter: nil))
        }
        return result
    }
    
    // map entries are (atom, count)
    init(map: [Int:Int]) {
        var g: [Glob] = []
        var n: Int = 0
        for size in map.keys {
            let count: Int = map[size] ?? 0
            assert((size > 0) && (count > 0))
            let glob = Glob(atom: size, count: count)
            g.append(glob)
            n += glob.n
        }
        self.globs = g.sorted(by: { $0.atom > $1.atom } )
        self.n = n
        assert(isValid())
    }
                
    init(appendTo: Partition, glob: Glob) {
        self.globs = Glob.order(globs: appendTo.globs + [glob])
        self.n = appendTo.n + glob.n
        assert(isValid())
    }
    
    init(glob: Glob) {
        self.globs = [glob]
        self.n = glob.n
        assert(isValid())
    }

    init(globs: [Glob]) {
        self.globs = Glob.order(globs: globs)
        self.n = globs.map( { $0.n } ).reduce(0,+)
        assert(isValid())
    }

    init(atoms: [Int]) {
        let g: [Glob] = atoms.map( {Glob(atom: $0, count: 1)} )
        self.globs = Glob.order(globs: g)
        self.n = globs.map( { $0.n } ).reduce(0,+)
        assert(isValid())
    }

    // for efficiency - store as a list of globs of strictly decreasing height
    public func isValid() -> Bool {
        if globs.isEmpty { return false }
        if n != globs.map( { $0.n } ).reduce(0,+) { return false }
        var height: Int = globs[0].atom
        for idx in 1..<globs.count {
            let prev = height
            height = globs[idx].atom
            if height >= prev {
                return false
            }
        }
        return true
    }

    public var description: String {
        var result: String = "\(globs[0])"
        for idx in 1..<globs.count {
            result += " + \(globs[idx])"
        }
        return result
    }
    
    func precedes(_ that: Partition) -> Bool {
        for idx in 0..<min(self.globs.count, that.globs.count) {
            let glob = self.globs[idx]
            let thatGlob = that.globs[idx]
            if glob.precedes(thatGlob) {
                return true
            } else if thatGlob.precedes(glob) {
                return false
            }
        }
        return self.globs.count > that.globs.count  // arbitrary - may never get here
    }
    
    public func ferrers() -> String {
        var result: String = ""
        for idx in 0..<globs.count {
            let glob = globs[idx]
            let line = String(repeating: "*", count: glob.atom) + "\n"
            for _ in 0..<glob.count { result.append(line) }
        }
        return result
    }
    
    static func filter(list: [Partition], atomFilter: AtomFilter) -> [Partition] {
        return list.filter( { $0.pure(atomFilter.predicate()) } )
    }
    
    // given an odd partition, create a diverse one
    public func oddToDiverse() -> Partition {
        assert(isOdd())
        var result: Partition = self
        while !result.isDiverse() {
            let g: [Glob] = result.globs.reduce([]) { (list,glob) in
                list + glob.take2()
            }
            result = Partition(globs: Glob.order(globs: g))
        }
        return result
    }
    
    public func mergeFirstAdjacent() -> Partition {
        assert(globs.count > 1)
        var next: Glob = globs.first!
        for idx in 1..<globs.count {
            let prev: Glob = next
            next = globs[idx]
            if prev.atom - next.atom == 1 {
                let pre: ArraySlice<Glob> = globs[0..<(idx-1)]
                let merge: Glob = Glob(atom: prev.atom + next.atom, count: 1)
                let post: ArraySlice<Glob> = globs[(idx+1)...]
                return Partition(globs: pre + [merge] + post)
            }
        }
        assert(false) // no adjacent atoms
    }
    
    // given an diverse partition, create an odd one
    public func diverseToOdd() -> Partition {
        assert(isDiverse())
        var result: Partition = self
        while !result.isOdd() {
            let g: [Glob] = result.globs.map( {$0.splitEven()} )
            result = Partition(globs: Glob.order(globs: g))
        }
        return result
    }
    
    // given a mod5 partition, create a diff2 one
    public func mod5ToDiff2() -> Partition {
        var result: Partition = self
        var done: Bool = false
        while !done {
            done = true
            var diffDone: Bool = false
            while !diffDone {
                if let temp = result.collapseDiff0() {
                    result = temp
                    done = false
                } else {
                    diffDone = true
                }
            }
            diffDone = false
            while !diffDone {
                if let temp = result.collapseDiff1() {
                    result = temp
                    done = false
                } else {
                    diffDone = true
                }
            }
        }
        return result
    }
    
    // Replace repeated atoms in a partition by combining them in pairs.
    // Return the new partition if it differs from the old one.
    public func collapseDiff0() -> Partition? {
        var gWrite: [Glob] = self.globs
        var changed: Bool = false
        var done: Bool = false
        while !done {
            done = true
            let gRead: [Glob] = gWrite
            gWrite = []
            for glob in gRead {
                if glob.count == 1 {
                    gWrite.append(glob)
                } else if glob.count == 2 {
                    gWrite.append(Glob(atom: 2 * glob.atom, count: 1))
                    done = false
                } else {
                    gWrite.append(Glob(atom: glob.atom, count: glob.count - 2))
                    gWrite.append(Glob(atom: 2 * glob.atom, count: 1))
                    done = false
                }
            }
            if !changed {
                if !done {
                    changed = true
                } else {
                    return nil
                }
            }
            gWrite = Glob.order(globs: gWrite)
        }
        return changed ? Partition(globs: gWrite) : nil
    }
    
    // Replace adjacent atoms in a partition by combining them in pairs.
    // Return the new partition if it differs from the old one.
    public func collapseDiff1() -> Partition? {
        assert( isDiverse() )
        var gWrite: [Glob] = self.globs
        var changed: Bool = false
        var done: Bool = false
        while !done {
            done = true
            let gRead: [Glob] = gWrite
            gWrite = []
            var next: Glob = gRead.first!
            var idx: Int = 1
            while idx < gRead.count {
                let prev: Glob = next
                next = gRead[idx]
                if prev.atom - next.atom >= 2 {
                    gWrite.append(prev)
                    idx += 1
                } else {
                    gWrite.append(Glob(atom: prev.atom + next.atom, count: 1))
                    done = false
                    idx += 1
                    if idx < gRead.count {
                        next = gRead[idx]
                        idx += 1
                    }
                }
            }
            if !changed {
                if !done {
                    changed = true
                } else {
                    return nil
                }
            }
            if !done {
                gWrite = Glob.order(globs: gWrite)
            } else {
                return changed ? Partition(globs: gRead) : nil
            }
        }
        return changed ? Partition(globs: gWrite) : nil
    }
    
    func height() -> Int { globs.last!.atom }
    func width() -> Int { globs.count }
    func isOdd() -> Bool { globs.allSatisfy( { $0.atom % 2 == 1 } ) }
    func isEven() -> Bool { globs.allSatisfy( { $0.atom % 2 == 0} ) }
    func isDiverse() -> Bool { globs.allSatisfy( { $0.count == 1} ) }
    func isOddCounts() -> Bool { globs.allSatisfy( { $0.count % 2 == 1} ) }
    func isEvenCounts() -> Bool { globs.allSatisfy( { $0.count % 2 == 0} ) }
    func isCongruent_5_1_4() -> Bool { globs.allSatisfy( { Partition.congruence_5_1_4.isCongruent($0.atom) } ) }
    func isDiff(minDiff: Int) -> Bool {
        isDiverse() &&
        pureDiff( predicate: { $0.atom - $1.atom >= minDiff })
    }
    func hasAdjacentAtoms() -> Bool { someDiff(predicate: { $0.atom - $1.atom == 1 } ) }
    func pure(_ predicate: GlobPredicate) -> Bool { globs.allSatisfy( { predicate($0) } ) }
    func pureDiff(predicate: (Glob,Glob) -> Bool) -> Bool {
        return zip(globs, globs.dropFirst()).allSatisfy { (prev, next) in
            predicate(prev, next)
        }
    }
    func some(_ predicate: GlobPredicate) -> Bool { globs.contains(where: { predicate($0) } ) }
    func someDiff(predicate: (Glob,Glob) -> Bool) -> Bool {
        return zip(globs, globs.dropFirst()).contains(where: { (prev, next) in
            predicate(prev, next) } )
    }

    func getPartitionClasses() -> Set<PartitionClass> {
        var result: Set<PartitionClass> = []
        if isOdd() { result.insert(.odd) }
        if isDiverse() { result.insert(.diverse) }
        return result
    }
    
}

struct PartitionSet: Equatable {
    private(set) var g: [Partition]
    
    init(list: [Partition] = []) {
        let unsorted: [Partition] = Array( Set(list) )
        self.g = unsorted.sorted(by: { $0.precedes($1) } )
    }
    
    var count: Int { return g.count }
    
    func printList() -> String { g.reduce("") { $0 + $1.description + "\n" } }
    
    static func firstDiff(a: PartitionSet, b: PartitionSet) -> Int? {
        let last: Int = min(a.count, b.count)
        for idx in 0..<last { if a.g[idx] != b.g[idx] { return idx } }
        return a.count == b.count ? nil : last
    }
    
//    static func diff2ToMod5Transform(_ partition: Partition) -> Partition {
//        var result: Partition = partition
//        while !result.isDiff(minDiff: 2) {
//            if result.hasAdjacentAtoms() {
//                result = result.mergeFirstAdjacent()
//            } else if !result.isDiverse() {
//                let g: [Glob] = result.globs.reduce([]) { (list,glob) in
//                    list + glob.take2()
//                }
//                result = Partition(globs: Glob.order(globs: g))
//            } else {
//                DebugUtl.needMoreLogic()
//            }
//        }
//        return result
//    }
    
    // given a diff2 partition, create a mod5 one
    static func diff2ToMod5Transform(_ partition: Partition) -> Partition {
//        var globMap: [Int : [Glob]] = [ : ]
        let atomList: [Int] = Glob.atomize(globs: partition.globs, increasing: true)
        var g: [Glob] = []
        for atom in atomList {
            let split: [Int] = asMod5Sum( atom )
            for key in split {
                assert( Partition.congruence_5_1_4.isCongruent(key) )
                g.append(Glob(atom: key, count: 1))
            }
        }
        return Partition(globs: g)
    }
    
    static func asMod5Sum(_ atom: Int) -> [Int] {
        assert(atom > 0)
        switch atom % 10 {
        case 0: return [atom/2 - 1, atom - (atom/2 - 1)]
        case 2: return [atom/2, atom - (atom/2)]
        case 3: return atom == 3 ? [1, 1, 1] : [atom/2 - 2, atom - (atom/2)]
        case 5: return atom == 5 ? [1, 1, 1, 1, 1] : [atom/2 - 1, atom - (atom/2 - 1)]
        case 7: return atom == 7 ? [1, 1, 1, 1, 1, 1,1] : [atom/2 - 2, atom - (atom/2 - 2)]
        case 8: return [atom/2, atom - (atom/2)]
        default: return [atom]
        }
    }
    
    static func mod5ToDiff2Transform(_ partition: Partition) -> Partition {
        var result: Partition = partition
        while !result.isDiff(minDiff: 2) {
            if result.hasAdjacentAtoms() {
                result = result.mergeFirstAdjacent()
            } else if !result.isDiverse() {
                let g: [Glob] = result.globs.reduce([]) { (list,glob) in
                    list + glob.take2()
                }
                result = Partition(globs: Glob.order(globs: g))
            } else {
                DebugUtl.needMoreLogic()
            }
        }
        return result
    }
    
    static func testTransform(from: PartitionSet, to: PartitionSet, transform: (Partition) -> Partition) -> Bool {
        var map: [Partition:Partition] = [:]
        var mapInv: [Partition:Partition] = [:]
        for item in from.g {
            let value = transform(item)
            if let prevItem: Partition = mapInv[value] {
                DebugUtl.needMoreLogic("both \(item) and \(prevItem) map to \(value)")
            }
            map.updateValue(value, forKey: item)
            mapInv.updateValue(item, forKey: value)
        }
        return map.values.count == to.count
    }

}

enum PartitionClass: CustomStringConvertible {
    case odd
    case diverse
    
    public var description: String {
        switch self {
        case .odd: return "odd"
        case .diverse: return "diverse"
        }
    }
    
    static func print(list: Set<PartitionClass>) -> String {
        var result: String = ""
        var prefix: String = ""
        for item in list {
            result += prefix + item.description
            prefix = " "
        }
        return result
    }
}

struct SublistSpec: Validity, Hashable, Equatable {
    let n: Int
    let maxHeight: Int
    let minDiff: Int?
    let atomFilter: AtomFilter?

    init(n: Int, maxHeight: Int, minDiff: Int?, atomFilter: AtomFilter?) {
        self.n = n
        self.maxHeight = maxHeight
        self.minDiff = minDiff
        self.atomFilter = atomFilter
        assert(isValid())
    }
    
    func isValid() -> Bool { (n >= 1) && (maxHeight >= 1) && (n >= maxHeight)
        && ((minDiff == nil) || (atomFilter == nil)) }
}

// a partition unit of identical atoms
// atom is the size of each atom and count is the number of atoms
struct Glob: Validity, Hashable, Equatable, CustomStringConvertible {
    let atom: Int
    let count: Int
    init(atom: Int, count: Int) {
        self.atom = atom
        self.count = count
        assert(isValid())
    }
                
    // both atom and count are positive
    func isValid() -> Bool { (atom > 0) && (count > 0) }
    
    static func == (lhs: Glob, rhs: Glob) -> Bool {
        return (lhs.atom == rhs.atom) && (lhs.count == rhs.count)
    }

    func precedes(_ that: Glob) -> Bool {
        if self.atom > that.atom {
            return true
        } else if self.atom < that.atom {
            return false
        } else {
            return self.count > that.count
        }
    }

    var description: String {
        var result: String = "\(atom)"
        for _ in 1..<count {
            result += " + \(atom)"
        }
        return result
    }
    
    // prepare globs for Partition validity: non-empty and with decreasing atom size
    static func order(globs: [Glob]) -> [Glob] {
        assert(!globs.isEmpty)
        // sort
        let gSorted: [Glob] = globs.sorted(by: { $0.atom > $1.atom } )
        // consolidate
        var gFinal: [Glob] = [gSorted.first!]
        for idx in 1..<gSorted.count {
            if gFinal.last!.atom == gSorted[idx].atom {
                gFinal[gFinal.count-1] = Glob(atom: gFinal.last!.atom, count: gFinal.last!.count + gSorted[idx].count)
            } else {
                gFinal.append(gSorted[idx])
            }
        }
        return gFinal
    }
    
    // return a sorted list of atoms after splitting apart all globs
    static func atomize(globs: [Glob], increasing: Bool) -> [Int] {
        var atoms: [Int] = []
        for glob in globs {
            for _ in 0..<glob.count {
                atoms.append( glob.atom )
            }
        }
        return atoms.sorted(by: { increasing ? $0 < $1 : $1 < $0 } )
    }
    
    var n: Int { atom * count }

    // Idempotent
    func compress() -> Glob { return Glob(atom: n, count: 1) }
    func expand() -> Glob { return Glob(atom: 1, count: n) }

    // SelfInverse
    func swap() -> Glob { return Glob(atom: count, count: atom) }
    
    func take1() -> [Glob] {
        if count == 1 {
            return [self]
        } else if count == 2 {
            return [Glob(atom: 2 * atom, count: 1)]
        } else {
            return [Glob(atom: atom, count: 1), Glob(atom: (count - 1) * atom, count: 1)]
        }
    }
    
    func take2() -> [Glob] {
        if count == 1 {
            return [self]
        } else if count == 2 {
            return [Glob(atom: 2 * atom, count: 1)]
        } else {
            return [Glob(atom: atom, count: count - 2), Glob(atom: 2 * atom, count: 1)]
        }
    }
    
    func splitEven() -> Glob {
        if atom % 2 == 1 {
            return self
        } else {
            return Glob(atom: atom / 2, count: 2 * count)
        }
    }
    
    func allSubsets(of set: Set<Glob>) -> [Set<Glob>] {
        let array = Array(set)
        var subsets: [Set<Glob>] = []
        
        for i in 0..<(1 << array.count) {
            var subset: Set<Glob> = []
            for j in 0..<array.count {
                if (i & (1 << j)) != 0 {
                    subset.insert(array[j])
                }
            }
            subsets.append(subset)
        }
        return subsets
    }
    
    struct SubsetSequence: Sequence {
        let set: [Glob]
        func makeIterator() -> SubsetIterator {
            return SubsetIterator(set)
        }
    }

    struct SubsetIterator: IteratorProtocol {
        let set: [Glob]
        var subsetIndex: Int
        
        init(_ set: [Glob]) {
            self.set = set
            self.subsetIndex = 0
        }
        
        mutating func next() -> Set<Glob>? {
            if subsetIndex < (1 << set.count) {
                var subset = Set<Glob>()
                for j in 0..<set.count {
                    if (subsetIndex & (1 << j)) != 0 {
                        subset.insert(set[j])
                    }
                }
                subsetIndex += 1
                return subset
            } else {
                return nil
            }
        }
    }
}

// an ordered list of partitions of n each of whose highest glob is maxHeight
public class Sublist {
    let sublistSpec: SublistSpec
    var list: [Partition]
    
    private(set) static var memo: [SublistSpec : Sublist] = [:]
    static func lookUp(_ sublistSpec: SublistSpec) -> Sublist {
        if let result = memo[sublistSpec] {
            return result
        } else {
            let result: Sublist = Sublist(sublistSpec: sublistSpec)
            memo[sublistSpec] = result
            return result
        }
    }
    private(set) static var memoCount: [SublistSpec : Int] = [:]
    static func lookUpCount(_ nMaxHeight: SublistSpec) -> Int {
        if let result = memoCount[nMaxHeight] {
            return result
        } else {
            let result = Sublist.count(sublistSpec: nMaxHeight)
            memoCount[nMaxHeight] = result
            return result
        }
    }

    private init(sublistSpec: SublistSpec) {
        // TODO? note that we don't currently allow sublistSpec to have both filters
        // perhaps this can be eased later
        self.sublistSpec = sublistSpec
        if self.sublistSpec.atomFilter != nil {
            self.list = Sublist.initAtomFilter(sublistSpec: sublistSpec)
        } else if self.sublistSpec.minDiff != nil {
            self.list = Sublist.initDiffFilter(sublistSpec: sublistSpec)
        } else {
            self.list = Sublist.initNoFilter(sublistSpec: sublistSpec)
        }
    }
    
    private static func initNoFilter(sublistSpec: SublistSpec) -> [Partition] {
        if sublistSpec.maxHeight == 1 {
            return [Partition(glob: Glob(atom: 1, count: sublistSpec.n))]
        }
        var result: [Partition] = []
        let maxCount = sublistSpec.n / sublistSpec.maxHeight
        for count in 1...maxCount {
            let glob = Glob(atom: sublistSpec.maxHeight, count: count)
            let r = sublistSpec.n - glob.n
            if r == 0 {
                result.append(Partition(glob: glob))
            } else {
                for atom in 1...min(sublistSpec.maxHeight - 1, r) {
                    let subList: Sublist = Sublist.lookUp(SublistSpec(n: r, maxHeight: atom, minDiff: sublistSpec.minDiff, atomFilter: sublistSpec.atomFilter))
                    for item in subList.list {
                        result.append(Partition(appendTo: item, glob: glob))
                    }
                }
            }
        }
        return result
    }

    private static func initAtomFilter(sublistSpec: SublistSpec) -> [Partition] {
        if sublistSpec.maxHeight == 1 {
            assert( sublistSpec.atomFilter!.accept(1) != false )
            return [Partition(glob: Glob(atom: 1, count: sublistSpec.n))]
        }
        var result: [Partition] = []
        let maxCount = sublistSpec.n / sublistSpec.maxHeight
        for count in 1...maxCount {
            let glob = Glob(atom: sublistSpec.maxHeight, count: count)
            let r = sublistSpec.n - glob.n
            if r == 0 {
                result.append(Partition(glob: glob))
            } else {
                for atom in 1...min(sublistSpec.maxHeight - 1, r) {
                    if sublistSpec.atomFilter!.accept(atom) {
                        let subList: Sublist = Sublist.lookUp(SublistSpec(n: r, maxHeight: atom, minDiff: sublistSpec.minDiff, atomFilter: sublistSpec.atomFilter))
                        for item in subList.list {
                            result.append(Partition(appendTo: item, glob: glob))
                        }
                    }
                }
            }
        }
        return result
    }

    private static func initDiffFilter(sublistSpec: SublistSpec) -> [Partition] {
        if sublistSpec.maxHeight == 1 {
            return sublistSpec.n == 1 ? [Partition(glob: Glob(atom: 1, count: sublistSpec.n))] : []
        }
        var result: [Partition] = []
        let glob = Glob(atom: sublistSpec.maxHeight, count: 1)
        let r = sublistSpec.n - glob.n
        if r == 0 {
            result.append(Partition(glob: glob))
        } else {
            let max: Int = min(sublistSpec.maxHeight - sublistSpec.minDiff!, r)
            if max >= 1 {
                for atom in 1...max {
                    let subList: Sublist = Sublist.lookUp(SublistSpec(n: r, maxHeight: atom, minDiff: sublistSpec.minDiff, atomFilter: sublistSpec.atomFilter))
                    for item in subList.list {
                        result.append(Partition(appendTo: item, glob: glob))
                    }
                }
            }
        }
        return result
    }

    static func count(sublistSpec: SublistSpec) -> Int {
        if sublistSpec.maxHeight == 1 {
            return 1 // self.list = [Partition(glob: Glob(atom: 1, count: nMaxHeight.n))]
        } else {
            var total: Int = 0
            let maxCount = sublistSpec.n / sublistSpec.maxHeight
            for count in 1...maxCount {
                let glob = Glob(atom: sublistSpec.maxHeight, count: count)
                let r = sublistSpec.n - glob.n
                if r == 0 {
                    total += 1 // self.list.append(Partition(glob: glob))
                } else {
                    for atom in 1...min(sublistSpec.maxHeight - 1, r) {
                        let subTotal: Int = Sublist.lookUpCount(SublistSpec(n: r, maxHeight: atom, minDiff: sublistSpec.minDiff, atomFilter: sublistSpec.atomFilter))
                        total += subTotal // self.list.append(Partition(glob: glob))
                    }
                }
            }
            return total
        }
    }
}

struct Residues: Validity, Hashable {
    let n: Int
    let residues: Set<Int>
    
    init(n: Int, value: Int) {
        self.n = n
        self.residues = [value % n]
        assert(isValid())
    }
    
    init(n: Int, values: [Int]) {
        self.n = n
        self.residues = Set(values.map( {$0 % n} ))
        assert(isValid())
    }
    
    func isValid() -> Bool {
        if n < 2 { return false }
        for r in residues {
            if (r < 0) || (r >= n) { return false }
        }
        return true
    }
    
    func isCongruent(_ testMe: Int) -> Bool { residues.contains( testMe % n) }
}

typealias IntPredicate = (Int) -> Bool
typealias GlobPredicate = (Glob) -> Bool
typealias GlobDiffPredicate = (Glob, Glob) -> Bool

enum AtomFilter: Hashable {
    case mod (residues: Residues)
    
    func predicate() -> GlobPredicate {
        switch self {
        case .mod: { accept($0.atom) }
        }
    }
    
    func accept(_ atom: Int) -> Bool {
        switch self {
        case .mod (let residue): residue.isCongruent(atom)
        }
    }
}
