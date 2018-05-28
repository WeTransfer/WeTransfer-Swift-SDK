//
//  ChunksTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 28/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

class UploadTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
		TestConfiguration.configure(environment: .live)
	}
	
	override func tearDown() {
		super.tearDown()
		TestConfiguration.resetConfiguration()
	}
	
	func testFileUpload() {
		
		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}
		
		let transferSentExpectation = expectation(description: "Transfer is sent")
		let transfer = Transfer(name: "Test transfer", description: nil, files: [file])
		
		try? WeTransfer.createTransfer(with: transfer, completion: { (result) in
			if case .failure(let error) = result {
				XCTFail(error.localizedDescription)
				return
			}
			WeTransfer.send(transfer, stateChanged: { (state) in
				switch state {
				case .failed(let error):
					XCTFail(error.localizedDescription)
					transferSentExpectation.fulfill()
				case .completed:
					transferSentExpectation.fulfill()
				default:
					break
				}
			})
		})
		
		waitForExpectations(timeout: 60) { (error) in
			if let url = transfer.shortURL {
				print("Transfer uploaded: \(url)")
			}
			XCTAssertNotNil(transfer.shortURL)
			for file in transfer.files {
				XCTAssertTrue(file.uploaded)
			}
		}
	}
	
}
