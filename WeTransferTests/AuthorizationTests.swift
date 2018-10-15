//
//  SimpleTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class AuthorizationTests: BaseTestCase {

	func testUnauthorized() {
		do {
			_ = try WeTransfer.client.createRequest(.createTransfer())
		} catch {
			XCTAssertEqual(error.localizedDescription, WeTransfer.Error.notAuthorized.localizedDescription)
		}
	}

	func testAuthorization() {
		let authorizedExpectation = expectation(description: "Authorization should succeed")
		WeTransfer.authorize { (result) in
			if case .failure(let error) = result {
				XCTFail("Authorization failed: \(error)")
			}
			authorizedExpectation.fulfill()
		}

		waitForExpectations(timeout: 10) { _ in }
	}
	
	func testWrongJWTKey() {
		let authFailExpectation = expectation(description: "Request should failed")
		TestConfiguration.fakeAuthorize()
		let board = Board(name: "Bad Transfer", description: nil)
		WeTransfer.createExternalBoard(board) { result in
			if case .success = result {
				XCTFail("Request did not fail (like it should)")
			}
			authFailExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 10) { _ in	}
	}

}
