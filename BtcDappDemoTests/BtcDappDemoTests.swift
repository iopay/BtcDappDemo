//
//  BtcDappDemoTests.swift
//  BtcDappDemoTests
//
//  Created by liugang zhang on 2024/3/19.
//

import XCTest
@testable import BtcDappDemo

final class BtcDappDemoTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMagicHash() throws {
        let hash = magicHash(message: "hello world~")
        XCTAssertEqual(hash.hex, "22d290bee19f60ac03256c95751334c8e5a3377394f702cef84910f9ff694503")

        let (signature, i) = signMessage(hash, key: privateKey.data)
        print(signature.hex, i)
        let res = ([UInt8(i + 27 + 4)] + signature).toBase64()
        print(res)
        XCTAssertEqual(res, "HxEwfYwhG/DS/PAfyDE9gFSSD133nL8pifFjQyuH9tXHVErO2ZW28WeUgU0UY1Bh0cv/aie7W8ydKryBr1ZwNMI=")
    }

}
