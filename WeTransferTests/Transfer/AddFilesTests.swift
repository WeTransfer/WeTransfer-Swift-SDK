//
//  AddFilesTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

class AddFilesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
		TestConfiguration.configure(environment: .live)
    }
    
    override func tearDown() {
        super.tearDown()
		TestConfiguration.resetConfiguration()
    }
	
	func testAddingFilesToTransferModel() {
		let transfer = Transfer(name: "Test Transfer", description: nil)
		guard let file = TestConfiguration.fileModel else {
			XCTFail("Could not create file model")
			return
		}
		
		transfer.addFiles([file])
		XCTAssertTrue(transfer.files.contains(file))
		XCTAssertEqual(transfer.files.count, 1)
		
		transfer.addFiles([file])
		XCTAssertEqual(transfer.files.count, 1)
	}
	
	func testFileModel() {
		guard let _ = TestConfiguration.imageFileURL else {
			XCTFail("Test image not found")
			return
		}
		
		guard let file = TestConfiguration.fileModel else {
			XCTFail("Could not create file model")
			return
		}
		
		XCTAssertNil(file.identifier)
		XCTAssertFalse(file.uploaded)
		XCTAssertNil(file.numberOfChunks)
		XCTAssert(file.chunks.isEmpty)
		XCTAssertNil(file.multipartUploadIdentifier)
		XCTAssertEqual(file.filesize, 1200480, "File size not equal")
	}
	
	func testAddFilesRequest() {
		let transfer = Transfer(name: "Test Transfer", description: nil)
		
		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}
		
		let addedFilesExpectation = expectation(description: "Files are added")
		
		try? WeTransfer.createTransfer(with: transfer, completion: { (result) in
			if case .failure(let error) = result {
				XCTFail(error.localizedDescription)
				return
			}
			
			do {
				try WeTransfer.onlyAddFiles([file], to: transfer, completion: { (result) in
					if case .failure(let error) = result {
						XCTFail(error.localizedDescription)
						return
					}
					addedFilesExpectation.fulfill()
				})
			} catch {
				XCTFail(error.localizedDescription)
				addedFilesExpectation.fulfill()
			}
		})
		
		waitForExpectations(timeout: 10) { (error) in
			XCTAssertFalse(transfer.files.isEmpty)
			for file in transfer.files {
				XCTAssertNotNil(file.identifier)
				XCTAssertFalse(file.uploaded)
			}
		}
	}
	
}
