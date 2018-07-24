//
//  SimpleTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class SimpleTransferTests: XCTestCase {

	override func setUp() {
		super.setUp()
		TestConfiguration.configure(environment: .production)
	}

	override func tearDown() {
		super.tearDown()
		TestConfiguration.resetConfiguration()
	}

	func testSimpleTransfer() {

		guard let fileURL = TestConfiguration.imageFileURL else {
			XCTFail("Test image not found")
			return
		}

		let simpleTransferExpectation = expectation(description: "Transfer has been sent")
		var updatedTransfer: Transfer?
		var timer: Timer?
		
		WeTransfer.uploadTransfer(named: "Test Transfer", containing: [fileURL]) { state in
			switch state {
			case .created(let transfer):
				print("Transfer created: \(transfer)")
			case .uploading(let progress):
				print("Transfer started...")
				timer = Timer(timeInterval: 1 / 30, repeats: true, block: { _ in
					print("Progress: \(progress.fractionCompleted)")
				})
				RunLoop.main.add(timer!, forMode: .commonModes)
			case .completed(let transfer):
				timer?.invalidate()
				timer = nil
				print("Transfer sent: \(String(describing: transfer.shortURL))")
				updatedTransfer = transfer
				simpleTransferExpectation.fulfill()
			case .failed(let error):
				timer?.invalidate()
				timer = nil
				XCTFail("Transfer failed: \(error)")
				simpleTransferExpectation.fulfill()
			}
		}

		waitForExpectations(timeout: 60) { _ in
			XCTAssertNotNil(updatedTransfer, "Transfer was not completed")
		}
	}

}
