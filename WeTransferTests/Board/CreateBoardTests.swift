//
//  CreateTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 01/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class CreateBoardTests: BaseTestCase {

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
