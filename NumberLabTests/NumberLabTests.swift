//
//  NumberLabTests.swift
//  NumberLabTests
//
//  Created by Macintosh on 4/30/23.
//

import XCTest
@testable import NumberLab

final class NumberLabTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
