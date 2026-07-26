//
//  NumberLabTests.swift
//  NumberLabTests
//
//  Created by Macintosh on 4/30/23.
//

import XCTest
import Graphics2D
@testable import NumberLab

final class NumberLabTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Graphics2D (1000x1000 hand-settable pixel image)

    func testGraphics2DPixelMatrix1000x1000() throws {
        let width = 1000
        let height = 1000
        let matrix = PixelMatrix(type: .rgba, nrow: height, ncol: width)

        // Set a handful of individual pixels by hand.
        matrix.set(row: 0, col: 0, rawPixel: [255, 0, 0, 255])
        matrix.set(row: 999, col: 999, rawPixel: [0, 255, 0, 255])
        matrix.set(row: 500, col: 500, rawPixel: [0, 0, 255, 255])

        guard let image = CGImage.create(pixelMatrix: matrix) else {
            return XCTFail("CGImage.create(pixelMatrix:) returned nil")
        }
        XCTAssertEqual(image.width, width)
        XCTAssertEqual(image.height, height)

        guard let roundTripped = image.getPixelMatrix() else {
            return XCTFail("getPixelMatrix() returned nil")
        }
        XCTAssertEqual(roundTripped.get(row: 0, col: 0), [255, 0, 0, 255])
        XCTAssertEqual(roundTripped.get(row: 999, col: 999), [0, 255, 0, 255])
        XCTAssertEqual(roundTripped.get(row: 500, col: 500), [0, 0, 255, 255])
    }

    // MARK: - NLimb cross-validation against NBit

    func testNLimbAsInt() throws {
        for k in 1...200 {
            let bit  = try NBit(n: k)
            let limb = try NLimb(n: k)
            XCTAssertEqual(bit.asInt(), limb.asInt(), "asInt mismatch at k=\(k)")
        }
    }

    func testNLimbAddition() throws {
        for a in 1...50 {
            for b in 1...50 {
                let sum = (try NBit(n: a) + NBit(n: b)).asInt()
                let lum = (try NLimb(n: a) + NLimb(n: b)).asInt()
                XCTAssertEqual(sum, lum, "addition mismatch: \(a)+\(b)")
            }
        }
    }

    func testNLimbSubtraction() throws {
        for a in 2...60 {
            for b in 1..<a {
                let dif = (try NBit(n: a) - NBit(n: b)).asInt()
                let lum = (try NLimb(n: a) - NLimb(n: b)).asInt()
                XCTAssertEqual(dif, lum, "subtraction mismatch: \(a)-\(b)")
            }
        }
    }

    func testNLimbMultiplication() throws {
        for a in 1...30 {
            for b in 1...30 {
                let prod = (try NBit(n: a) * NBit(n: b)).asInt()
                let lum  = (try NLimb(n: a) * NLimb(n: b)).asInt()
                XCTAssertEqual(prod, lum, "multiplication mismatch: \(a)*\(b)")
            }
        }
    }

    func testNLimbComparison() throws {
        for a in 1...40 {
            for b in 1...40 {
                let bitCmp  = NBit.compare(try NBit(n: a), try NBit(n: b))
                let limbCmp = NLimb.compare(try NLimb(n: a), try NLimb(n: b))
                XCTAssertEqual(bitCmp, limbCmp, "comparison mismatch: \(a) vs \(b)")
            }
        }
    }

    func testNLimbDivideBy3() throws {
        for k in 1...100 {
            let (bq, br) = try! NBit(n: k).divideBy3()
            let (lq, lr) = try! NLimb(n: k).divideBy3()
            let bqInt = { if case .n(let n) = bq { return n.asInt() } else { return 0 } }()
            let lqInt = { if case .n(let n) = lq { return n.asInt() } else { return 0 } }()
            XCTAssertEqual(bqInt, lqInt, "divideBy3 quotient mismatch at k=\(k)")
            XCTAssertEqual(br,    lr,    "divideBy3 remainder mismatch at k=\(k)")
        }
    }

    func testOddLimbCollatzChain() throws {
        for ordinal in 0...40 {
            let bitChain  = try OddBit(ordinal: ordinal).collatzChain().map { $0.asInt() }
            let limbChain = try OddLimb(ordinal: ordinal).collatzChain().map { $0.asInt() }
            XCTAssertEqual(bitChain, limbChain, "collatzChain mismatch at ordinal=\(ordinal)")
        }
    }

    // MARK: - N.gcd

    func testGcdBasic() throws {
        let n12 = try N(n: 12)
        let n8  = try N(n: 8)
        let g   = N.gcd(n12, n8)
        XCTAssertEqual(try g.asInt(), 4)
    }

    func testGcdCoprime() throws {
        let n7 = try N(n: 7)
        let n3 = try N(n: 3)
        let g  = N.gcd(n7, n3)
        XCTAssertEqual(try g.asInt(), 1)
    }

    func testGcdSame() throws {
        let n5 = try N(n: 5)
        let g  = N.gcd(n5, n5)
        XCTAssertEqual(try g.asInt(), 5)
    }

    func testGcdWithOne() throws {
        let n1  = try N(n: 1)
        let n17 = try N(n: 17)
        XCTAssertEqual(try N.gcd(n1, n17).asInt(), 1)
        XCTAssertEqual(try N.gcd(n17, n1).asInt(), 1)
    }

    // MARK: - I construction

    func testIZero() throws {
        XCTAssertEqual(I.zero, try I(int: 0))
    }

    func testIPositive() throws {
        let i5 = try I(int: 5)
        XCTAssertFalse(i5.negative)
        XCTAssertEqual(i5.description, "101")  // 5 in LSB-first binary
    }

    func testINegative() throws {
        let iNeg3 = try I(int: -3)
        XCTAssertTrue(iNeg3.negative)
        XCTAssertEqual(iNeg3.description, "-11")  // 3 in LSB-first binary
    }

    func testIAbsValue() throws {
        let iNeg6 = try I(int: -6)
        let i6    = try I(int:  6)
        XCTAssertEqual(iNeg6.abs, i6)
    }

    // MARK: - I comparison

    func testIComparison() throws {
        let iNeg7 = try I(int: -7)
        let iNeg3 = try I(int: -3)
        let i2    = try I(int:  2)
        XCTAssertTrue(iNeg7 < iNeg3)
        XCTAssertTrue(iNeg3 < I.zero)
        XCTAssertTrue(I.zero < i2)
        XCTAssertTrue(iNeg7 < i2)
    }

    // MARK: - I arithmetic

    func testIAddSameSign() throws {
        let i3  = try I(int:  3)
        let i5  = try I(int:  5)
        let sum = i3 + i5
        XCTAssertEqual(sum, try I(int: 8))
    }

    func testIAddOppositeSign() throws {
        let i3     = try I(int:  3)
        let iNeg5  = try I(int: -5)
        let result = i3 + iNeg5
        XCTAssertEqual(result, try I(int: -2))

        let result2 = iNeg5 + i3
        XCTAssertEqual(result2, try I(int: -2))
    }

    func testIAddToZero() throws {
        let i4    = try I(int:  4)
        let iNeg4 = try I(int: -4)
        XCTAssertEqual(i4 + iNeg4, I.zero)
    }

    func testISubtract() throws {
        let i3    = try I(int: 3)
        let i5    = try I(int: 5)
        let iNeg2 = try I(int: -2)
        XCTAssertEqual(i3 - i5, iNeg2)
    }

    func testIMultiply() throws {
        let iNeg4 = try I(int: -4)
        let iNeg3 = try I(int: -3)
        let i12   = try I(int:  12)
        XCTAssertEqual(iNeg4 * iNeg3, i12)

        let i4    = try I(int: 4)
        let iNeg12 = try I(int: -12)
        XCTAssertEqual(i4 * iNeg3, iNeg12)
    }

    func testIMultiplyByZero() throws {
        let i7 = try I(int: 7)
        XCTAssertEqual(i7 * I.zero, I.zero)
        XCTAssertEqual(I.zero * i7, I.zero)
    }

    func testINegation() throws {
        let i5    = try I(int:  5)
        let iNeg5 = try I(int: -5)
        XCTAssertEqual(-i5, iNeg5)
        XCTAssertEqual(-iNeg5, i5)
        XCTAssertEqual(-I.zero, I.zero)
    }

}
