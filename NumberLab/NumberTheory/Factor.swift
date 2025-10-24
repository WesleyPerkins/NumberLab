import Foundation

struct Factor {
    
    // return highest power of p that is no larger than n
    func powerLessThan(p: Int, n: Int) -> Int {
        assert((p > 1) && (n > 0))
        var best: Int = 1
        var test: Int = p
        while test <= n {
            best = test
            test = best * p
        }
        return best
    }
}
