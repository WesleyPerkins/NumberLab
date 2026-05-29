import Foundation

enum NumberError: Error {
    case notNaturalNumber
    case notOdd
    case notOrdinal
    case overflow
    case emptyChain
    case collatzGraphError
}
