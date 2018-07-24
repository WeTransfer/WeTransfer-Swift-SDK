//
//  ChunksTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 28/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class UploadTests: XCTestCase {

	override func setUp() {
		super.setUp()
		TestConfiguration.configure(environment: .production)
	}

	override func tearDown() {
		super.tearDown()
		TestConfiguration.resetConfiguration()
	}
	
	var observation: NSKeyValueObservation?

	func testFileUpload() {

		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}

		let transferSentExpectation = expectation(description: "Transfer is sent")
		let transfer = Transfer(name: "Test transfer", description: nil, files: [file])
		
		WeTransfer.createTransfer(with: transfer, completion: { (result) in
			if case .failure(let error) = result {
				XCTFail("Transfer creation failed: \(error)")
				transferSentExpectation.fulfill()
				return
			}
			WeTransfer.upload(transfer, stateChanged: { (state) in
				switch state {
				case .created(let transfer):
					print("Transfer created: \(String(describing: transfer.identifier))")
				case .uploading(let progress):
					print("Upload started")
					var percentage = 0.0
					self.observation = progress.observe(\.fractionCompleted, changeHandler: { (progress, _) in
						let newPercentage = (progress.fractionCompleted * 100).rounded(FloatingPointRoundingRule.up)
						if newPercentage != percentage {
							percentage = newPercentage
							print("PROGRESS: \(newPercentage)% (\(progress.completedUnitCount) bytes)")
						}
					})
				case .failed(let error):
					XCTFail("Sending transfer failed: \(error)")
					transferSentExpectation.fulfill()
				case .completed:
					transferSentExpectation.fulfill()
				}
			})
		})

		waitForExpectations(timeout: 60) { _ in
			self.observation = nil
			if let url = transfer.shortURL {
				print("Transfer uploaded: \(url)")
			}
			XCTAssertNotNil(transfer.shortURL)
			for file in transfer.files {
				XCTAssertTrue(file.isUploaded)
			}
		}
	}

}
