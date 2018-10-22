//
//  ChunksTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 01/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class BoardUploadTests: BaseTestCase {
	
	var observation: NSKeyValueObservation?

	func testFileUpload() {

		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}

		let filesUploadedExpectation = expectation(description: "Files are uploaded")
		
		let board = Board(name: "Test Board", description: nil)
		WeTransfer.add([file], to: board) { (result) in
			if case .failure(let error) = result {
				XCTFail("Adding files failed: \(error)")
				filesUploadedExpectation.fulfill()
			}
			
			WeTransfer.upload(board, stateChanged: { (state) in
				switch state {
				case .created(let board):
					print("Transfer created: \(String(describing: board.identifier))")
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
					filesUploadedExpectation.fulfill()
				case .completed:
					filesUploadedExpectation.fulfill()
				}
			})
		}

		waitForExpectations(timeout: 60) { _ in
			self.observation = nil
			if let url = board.shortURL {
				print("Transfer uploaded: \(url)")
			}
			XCTAssertNotNil(board.shortURL)
			for file in board.files {
				XCTAssertTrue(file.isUploaded)
			}
		}
	}
}
