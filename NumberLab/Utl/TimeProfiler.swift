import Foundation

class TimeProfiler: CustomStringConvertible {
    let name: String
    let verbose: Bool = false

    private var start: Double?
    private var end: Double?
    private var prev: Double?
    private var currState: String?
    private var timeTable: [String: Double]  = [:]
    private var stateList: [String] = []

    init(name: String) {
        self.name = name
    }
    
    static func snap(name: String, _ f: () -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        f()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print("\(name) execution time: \(elapsed) seconds")
    }

    static func snap(name: String, _ f: () throws -> Void) rethrows {
        let start = CFAbsoluteTimeGetCurrent()
        try f()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        print("\(name) execution time: \(elapsed) seconds")
    }

    func measureExecutionTime<T>(_ function: () throws -> T) rethrows -> (result: T, executionTime: Double) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try function()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }
    static func snap<T>(_ f: () throws -> T) rethrows -> (result: T, elapsed: Double) {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try f()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        return (result, elapsed)
    }
    
    func start(state: String) {
        assert(!state.isEmpty)
        let now: Double = CFAbsoluteTimeGetCurrent()
        if state != currState {
            if currState != nil {
                var accum = timeTable[currState!] ?? 0.0
                accum += now - prev!
                timeTable.updateValue(accum, forKey: currState!)
                if (verbose) {
                    print("profiler: state: \(currState!) incremental time (seconds): \(accum)")
                }
            }
            currState = state
            prev = now
            if !stateList.contains(state) {
                stateList.append(state)
            }
        }
        if start == nil {
            start = now
        }
    }

    func finish() {
        assert(end == nil)
        let now: Double = CFAbsoluteTimeGetCurrent()
        if currState != nil {
            var accum = timeTable[currState!] ?? 0.0
            accum += now - prev!
            timeTable.updateValue(accum, forKey: currState!)
            if verbose {
                print("profiler: state: \(currState!) incremental time (seconds): \(accum)")
            }
        } else {
            start = now
        }
        end = now
    }

    var description: String {
        var s = "TimeProfiler: name: \(name): "
        if (start == nil) || (end == nil) {
            return s +  " execution is incomplete"
        }
        let total: Double = start!.distance(to: end!)
        s += "total time: \(String(format: "%.3f", total)) seconds"
        for state in stateList {
            let time = timeTable[state]
            let percent = 100.0 * time! / total
            // Skip steps that consume less than 1% of total time
            if percent >= 1.0 {
                let stime = String(format: "%.3f seconds (%.1f percent)", time!, percent)
                s += "\n  \(state): \(stime)"
            }
        }
        return s
    }

    func totalTime() -> Double? { (start == nil) || (end == nil) ? nil : end! - start! }

    func reset() {
        start = nil
        end = nil
        prev = nil
        currState = nil
        timeTable = [:]
        stateList = []
    }
}
