import Foundation

enum StackError: Error {
    case underflow
}

class Stack<T>: CustomStringConvertible {
    var data: [T]
    init(data: [T] = []) { self.data = data }
    func isEmpty() -> Bool { data.isEmpty }
    func count() -> Int { data.count }
    func pop() -> T? { data.isEmpty ? nil : data.removeLast() }
    func peek(offset: Int = 0) -> T? {
        (offset < data.count) ? data[(data.count - 1) - offset] : nil }
    func push(_ o: T) { data.append(o) }
    func clear() { data = [] }
    func replaceTop(_ value: T) throws {
        if data.isEmpty { throw StackError.underflow }
        data[data.count - 1] = value
    }
    
    // Default string representation (forward order)
    var description: String {
        "[\(data.map { "\($0)" }.joined(separator: ", "))]"
    }
    
    // Reverse order string representation
    var reverseDescription: String {
        "[\(data.reversed().map { "\($0)" }.joined(separator: ", "))]"
    }
}
