//
//  CreateTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class CreateBoardTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
		TestConfiguration.configure(environment: .production)
    }
    
    override func tearDown() {
        super.tearDown()
		TestConfiguration.resetConfiguration()
    }

	func testCreateBoardRequest() {
		let createdBoardExpectation = expectation(description: "Transfer is created")
		let board = Board(name: "Test Transfer", description: nil)
		WeTransfer.createExternalBoard(board, completion: { result in
			if case .failure(let error) = result {
				XCTFail("\(error.localizedDescription)")
			}
			createdBoardExpectation.fulfill()
		})
		waitForExpectations(timeout: 10) { _ in
			XCTAssertNotNil(board.identifier)
		}
	}
}