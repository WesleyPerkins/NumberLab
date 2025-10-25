import Foundation

class CollatzMap {
    private var map: [Odd: (Odd, N)]

    init() throws {
        self.map = [:]
        self.map.updateValue( (Odd.one, N.zero), forKey: Odd.one )
    }
    
    // next - Collatz value for this odd
    // pathCount - number of Collatz operations to get to Odd.one
    func link(_ odd: Odd) -> (Odd, N)? {
        if let (next, pathCount) = map[odd] {
            return (next, pathCount)
        }
        let stack: Stack<Odd> = Stack(data: [odd])
        while !stack.isEmpty() {
            var next: Odd = stack.peek()!.copy()
            next.collatz()
            if let (_, pathCount) = map[next] {
                var curr = stack.pop()!
                pathCount.inc()
                map.updateValue( (next, pathCount), forKey: curr )
                while !stack.isEmpty() {
                    next = curr
                    curr = stack.pop()!
                    pathCount.inc()
                    map.updateValue( (next, pathCount), forKey: curr )
                }
                return (next, pathCount)
            } else {
                stack.push(next)
            }
        }
        return nil
    }

}
