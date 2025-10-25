import SwiftUI

extension GeometryProxy {
    func isLandscape() -> Bool { size.isLandscape }
    func isVeryLandscape() -> Bool { size.isVeryLandscape }
    func h(_ scale: CGFloat) -> CGFloat { scale * size.height }
    func w(_ scale: CGFloat) -> CGFloat { scale * size.width }
    var hSpace: CGFloat { 15 }
    var vSpace: CGFloat { 15 }
    func barCorner() -> CGPoint {
        let x: CGFloat
        let y: CGFloat
        if isVeryLandscape() {
            x = safeAreaInsets.leading + size.width - 25
            y = safeAreaInsets.top + 30
        } else {
            x = safeAreaInsets.leading + size.width - 50
            y = safeAreaInsets.top + 30
        }
        return CGPoint(x: x, y: y)
    }
    func barCenter() -> CGPoint {
        let x = (safeAreaInsets.leading + size.width) / 2
        let y = safeAreaInsets.top + 30
        return CGPoint(x: x, y: y)
    }
    func browseInsets() -> EdgeInsets {
        if isVeryLandscape() {
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        } else {
            let top = safeAreaInsets.top
            return EdgeInsets(top: top + 20, leading: 0, bottom: 0, trailing: 40)
        }
    }
}
