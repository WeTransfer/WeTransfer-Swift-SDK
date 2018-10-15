//
//  SimpleTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 01/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class SimpleBoardUploadTests: BaseTestCase {

	func testSimpleUpload() {

		guard let fileURL = TestConfiguration.imageFileURL else {
			XCTFail("Test image not found")
			return
		}

		let simpleBoardUploadExpectation = expectation(description: "All files are uploaded")
		var updatedBoard: Board?
		var timer: Timer?
		
		WeTransfer.uploadBoard(named: "Test board", description: nil, containing: [fileURL]) { state in
			switch state {
			case .created(let board):
				print("Board created: \(board)")
			case .uploading(let progress):
				print("Uploading files...")
				timer = Timer(timeInterval: 1 / 30, repeats: true, block: { _ in
					print("Progress: \(progress.fractionCompleted)")
				})
				RunLoop.main.add(timer!, forMode: RunLoop.Mode.common)
			case .completed(let board):
				timer?.invalidate()
				timer = nil
				print("Files uploaded: \(String(describing: board.shortURL))")
				updatedBoard = board
				simpleBoardUploadExpectation.fulfill()
			case .failed(let error):
				timer?.invalidate()
				timer = nil
				XCTFail("Creation/upload failed: \(error)")
				simpleBoardUploadExpectation.fulfill()
			}
		}

		waitForExpectations(timeout: 60) { _ in
			XCTAssertNotNil(updatedBoard, "Board upload was not completed")
		}
	}
}
