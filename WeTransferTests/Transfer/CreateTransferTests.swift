//
//  CreateTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

class CreateTransferTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
		TestConfiguration.configure(environment: .live)
    }
    
    override func tearDown() {
        super.tearDown()
		TestConfiguration.resetConfiguration()
    }
	
	func testTransferModel() {
		let transfer = Transfer(name: "Test Transfer", description: nil)
		XCTAssertNil(transfer.identifier)
		XCTAssertNil(transfer.description)
		XCTAssert(transfer.files.isEmpty)
		XCTAssertNil(transfer.shortURL)
	}
	
	func testCreateTransferRequest() {
		let transfer = Transfer(name: "Test Transfer", description: nil)
		let createdTransferExpectation = expectation(description: "Transfer is created")
		do {
			try WeTransfer.createTransfer(with: transfer) { (result) in
				if case .failure(let error) = result {
					XCTFail(error.localizedDescription)
					return
				}
				createdTransferExpectation.fulfill()
			}
		} catch {
			XCTFail(error.localizedDescription)
			createdTransferExpectation.fulfill()
		}
		waitForExpectations(timeout: 10) {
			XCTAssertNotNil(transfer.identifier)
			XCTAssertNotNil(transfer.shortURL)
		}
	}
	
	func testTransforCreationWithFiles() {
		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}
		
		let createdTransferExpectation = expectation(description: "Transfer is created with files")
		
		let transfer = Transfer(name: "Test Transfer", description: nil, files: [file])
		do {
			try WeTransfer.createTransfer(with: transfer, completion: { (result) in
				if case .failure(let error) = result {
					XCTFail(error.localizedDescription)
					return
				}
				createdTransferExpectation.fulfill()
			})
		} catch {
			XCTFail(error.localizedDescription)
			createdTransferExpectation.fulfill()
		}
		
		waitForExpectations(timeout: 10) {
			XCTAssertNotNil(transfer.identifier)
			XCTAssertNotNil(transfer.shortURL)
			XCTAssertFalse(transfer.files.isEmpty)
			
			for file in transfer.files {
				XCTAssertNotNil(file.identifier)
				XCTAssertFalse(file.uploaded)
			}
		}
	}
    
}
