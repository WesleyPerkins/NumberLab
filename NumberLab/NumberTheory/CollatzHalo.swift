class CollatzHalo: CustomStringConvertible {
    var maxSolid: Odd           // we know all o are convergent for o <= maxSolid
    var haloSet: Set<Odd> = []  // set of known convergents > maxSolid

    init(copyMe: CollatzHalo? = nil) {
        if let copyMe = copyMe {
            self.maxSolid = copyMe.maxSolid
            self.haloSet = copyMe.haloSet
        } else {
            self.maxSolid = Odd.one
            self.haloSet = []
        }
    }

    static func copy(_ copyMe: CollatzHalo) -> CollatzHalo {
        return CollatzHalo(copyMe: copyMe)
    }

    // Process next candidate in-place
    func step() {
        let oCheck = maxSolid.successor
        var oNext = oCheck
        var haloPending: Set<Odd> = []  // set of newly known convergents > maxSolid
        while ( oNext > maxSolid ) && ( !haloSet.contains(oNext) ) {
            haloPending.insert(oNext)
            oNext = oNext.collatzed()
        }
        haloSet.formUnion( haloPending )
        assert( haloSet.contains(oCheck) )
        haloSet.remove(oCheck)
        maxSolid = oCheck
    }
    
    var description: String {
        let maxO = Double( haloSet.max()?.asInt() ?? 0 )
        let maxS = Double(maxSolid.asInt())
        let haloWidth = maxO == 0.0 ? 0.0 : Double( (maxO - maxS) )
        let haloWidthRelative = haloWidth / maxS
        let haloDensity = haloWidth > 0.0 ? Double(haloSet.count) / haloWidth : 0.0
        return "maxSolid: \(maxSolid) haloWidthRelative: \(haloWidthRelative) haloDensity: \(haloDensity)"
    }
}
    
