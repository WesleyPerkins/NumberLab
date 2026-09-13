import Foundation

class Queue<T> {
    var writeStack = Stack<T>()
    var readStack = Stack<T>()
    
    init(data: [T] = []) {
        self.readStack = Stack<T>()
        self.writeStack = Stack<T>(data: data)
    }

    func isEmpty() -> Bool { writeStack.isEmpty() && readStack.isEmpty() }
    func count() -> Int { writeStack.count() + readStack.count() }
    func remove() -> T? { canRead() ? readStack.pop() : nil }
    func peek() -> T? { canRead() ? readStack.peek() : nil }
    func add(_ o: T) { writeStack.push(o) }

    func canRead() -> Bool {
        if readStack.isEmpty() {
            if writeStack.isEmpty() {
                return false
            }
            while !writeStack.isEmpty() {
                readStack.push( writeStack.pop()! )
            }
        }
        return true
    }
    
}
