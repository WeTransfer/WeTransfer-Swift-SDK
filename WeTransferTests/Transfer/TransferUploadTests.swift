//
//  ChunksTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 28/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class TransferUploadTests: BaseTestCase {
	
	var observation: NSKeyValueObservation?

	private func createTransfer(completion: @escaping (Transfer?) -> Void) {
		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}
		
		WeTransfer.createTransfer(saying: "TestTransfer", fileURLs: [file.url]) { result in
			switch result {
			case .failure(let error):
				XCTFail("Transfer creation failed: \(error)")
				completion(nil)
				return
			case .success(let transfer):
				completion(transfer)
			}
		}
		
	}
	
	func testFileUpload() {

		let transferSentExpectation = expectation(description: "Transfer is sent")
		var resultTransfer: Transfer?
		
		createTransfer { (transfer) in
			guard let transfer = transfer else {
				transferSentExpectation.fulfill()
				return
			}
			resultTransfer = transfer
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
		}

		waitForExpectations(timeout: 60) { _ in
			guard let transfer = resultTransfer else {
				XCTFail("No transfer created")
				return
			}
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
