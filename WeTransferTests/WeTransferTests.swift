//
//  WeTransferTests.swift
//  WeTransfer Tests
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

class WeTransferTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
		
		let configuration = WeTransfer.Configuration(APIKey: "{YOUR_API_KEY_HERE}")
		WeTransfer.configure(with: configuration)
    }
    
    override func tearDown() {
        super.tearDown()
    }
	
	func testAuthorization() {
		let expectation = self.expectation(description: "Authorization should succeed")
		var receivedToken: String?
		do {
			try WeTransfer.authorize { (result) in
				switch result {
				case .success(let token):
					receivedToken = token
				case .failure(let error):
					XCTFail("Authorization failed: \(error)")
				}
				expectation.fulfill()
			}
		} catch {
			XCTFail("Authorization failed: \(error)")
		}
		
		waitForExpectations(timeout: 10) { (error) in
			XCTAssert(receivedToken != nil, "No token received from authorization call \(String(describing:error))")
		}
	}
	
	func testTransferCreation() {
		let expectation = self.expectation(description: "Transfer should be created")
		
		let transfer = Transfer(name: "Test transfer", description: nil)
		var updatedTransfer: Transfer?
		
		do {
			try WeTransfer.createTransfer(with: transfer, completion: { (result) in
				switch result {
				case .success(let transfer):
					updatedTransfer = transfer
					print("Created transfer at: \(String(describing: transfer.shortURL))")
				case .failure(let error):
					XCTFail("Error creating transfer: \(error)")
				}
				expectation.fulfill()
			})
		} catch {
			XCTFail("Transfer creation failed")
		}
		
		waitForExpectations(timeout: 10) { (error) in
			XCTAssertNotNil(updatedTransfer, "Transfer was not created: \(String(describing:error))")
		}
	}
	
	func testFileAdding() {
		
		let creationExpectation = self.expectation(description: "Transfer should be created")
		let filesAddedExpectation = self.expectation(description: "Files should be added")
		
		let transfer = Transfer(name: "Test Transfer", description: nil)
		var updatedTransfer: Transfer?
		
		let fileURL = Bundle(for: self.classForCoder).url(forResource: "image", withExtension: "jpg")
		
		try? WeTransfer.createTransfer(with: transfer, completion: { (result) in
			switch result {
			case .success(let transfer):
				guard let fileURL = fileURL, let file = File(url: fileURL) else {
					XCTFail("Test file not available")
					return
				}
				do {
					try WeTransfer.addFiles([file], to: transfer, completion: { (result) in
						switch result {
						case .success(let transfer):
								updatedTransfer = transfer
						case .failure(let error):
							XCTFail("Error adding file to transfer: \(error)")
						}
						filesAddedExpectation.fulfill()
					})
				} catch {
					XCTFail("Error adding files to transfer: \(error)")
				}
				
			case .failure(let error):
				XCTFail("Error creating transfer: \(error)")
			}
			creationExpectation.fulfill()
		})
		waitForExpectations(timeout: 10) { (error) in
			XCTAssertNotNil(updatedTransfer?.files.first, "Files not added to transfer \(String(describing: error))")
		}
	}
	
	func testChunkCreation() {
		let creationExpectation = self.expectation(description: "Transfer should be created")
		let filesAddedExpectation = self.expectation(description: "Files should be added")
		
		let transfer = Transfer(name: "Test Transfer", description: nil)
		var updatedTransfer: Transfer?
		
		let fileURL = Bundle(for: self.classForCoder).url(forResource: "image", withExtension: "jpg")
		
		try? WeTransfer.createTransfer(with: transfer, completion: { (result) in
			switch result {
			case .success(let transfer):
				guard let fileURL = fileURL, let file = File(url: fileURL) else {
					XCTFail("Test file not available")
					return
				}
				do {
					try WeTransfer.addFiles([file], to: transfer, completion: { (result) in
						switch result {
						case .success(let transfer):
							updatedTransfer = transfer
						case .failure(let error):
							XCTFail("Error adding files to transfer: \(error)")
						}
						filesAddedExpectation.fulfill()
					})
				} catch {
					XCTFail("Error adding files to transfer: \(error)")
				}
				
			case .failure(let error):
				XCTFail("Error creating transfer: \(error)")
			}
			creationExpectation.fulfill()
		})
		waitForExpectations(timeout: 10) { (error) in
			XCTAssertNotNil(updatedTransfer?.files.first?.chunks.first?.uploadURL, "URLs not added to chunks \(String(describing: error))")
		}
	}
	
	func testUpload() {
		let creationExpectation = self.expectation(description: "Transfer should be created")
		let filesAddedExpectation = self.expectation(description: "File should be added")
		let uploadedExpectation = self.expectation(description: "Transfer should be uploaded")
		
		let transfer = Transfer(name: "Test Transfer", description: nil)
		var updatedTransfer: Transfer?
		
		let fileURL = Bundle(for: self.classForCoder).url(forResource: "image", withExtension: "jpg")
		
		try? WeTransfer.createTransfer(with: transfer, completion: { (result) in
			switch result {
			case .success(let transfer):
				guard let fileURL = fileURL, let file = File(url: fileURL) else {
					XCTFail("Test file not available")
					return
				}
				try? WeTransfer.addFiles([file], to: transfer, completion: { (result) in
					switch result {
					case .success(let transfer):
						do {
							try WeTransfer.send(transfer, stateChanged: { (state) in
								switch state {
								case .completed(let transfer):
									print("FINISHED: \(String(describing: transfer.shortURL))")
									uploadedExpectation.fulfill()
								case .failed(let error):
									XCTFail("Error! \(error)")
								default:
									break
								}
							})
						} catch {
							XCTFail("Starting transfer failed: \(error)")
						}
						updatedTransfer = transfer
					case .failure(let error):
						XCTFail("Error adding files to transfer: \(error)")
					}
					filesAddedExpectation.fulfill()
				})
				
			case .failure(let error):
				XCTFail("Error creating transfer: \(error)")
			}
			creationExpectation.fulfill()
		})
		waitForExpectations(timeout: 120) { (error) in
			XCTAssertNotNil(updatedTransfer?.files.first?.chunks.first?.uploadURL, "URLs not added to chunks \(String(describing: error))")
		}
	}
}
