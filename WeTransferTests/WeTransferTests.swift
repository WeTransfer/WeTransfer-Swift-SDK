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
			XCTAssert(updatedTransfer != nil, "Transfer was not created: \(String(describing:error))")
		}
	}
}
