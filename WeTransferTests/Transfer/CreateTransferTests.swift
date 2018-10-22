//
//  CreateTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class CreateTransferTests: BaseTestCase {

	func testCreateTransferRequest() {
		guard let fileURL = TestConfiguration.imageFileURL else {
			XCTFail("File not available")
			return
		}
		
		let createdTransferExpectation = expectation(description: "Transfer is created")
		var transferResult: Transfer?
		WeTransfer.createTransfer(saying: "Test transfer", fileURLs: [fileURL]) { result in
			switch result {
			case .success(let transfer):
				transferResult = transfer
			case .failure(let error):
				XCTFail("\(error.localizedDescription)")
			}
			createdTransferExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 10) { _ in
			XCTAssertNotNil(transferResult)
			if let transfer = transferResult {
				XCTAssertFalse(transfer.files.isEmpty)
				for file in transfer.files {
					XCTAssertNotNil(file.identifier)
					XCTAssertFalse(file.isUploaded)
					XCTAssertNotNil(file.numberOfChunks)
				}
			}
		}
	}
}
