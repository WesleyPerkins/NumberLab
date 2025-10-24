import Foundation

struct DebugUtl {
    static func needMoreLogic(_ msg: String? = nil) {
        if msg != nil { print(msg!) }
        assert(false)
    }
}
