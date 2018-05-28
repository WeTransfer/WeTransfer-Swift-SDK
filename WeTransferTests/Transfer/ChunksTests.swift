//
//  ChunksTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 28/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

class ChunksTests: XCTestCase {

	override func setUp() {
		super.setUp()
		TestConfiguration.configure(environment: .live)
	}

	override func tearDown() {
		super.tearDown()
		TestConfiguration.resetConfiguration()
	}

	func testChunkCreationRequest() {
		let transfer = Transfer(name: "Test Transfer", description: nil)

		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}

		var updatedFile: File?

		let createdChunksExpectation = expectation(description: "Chunks are created")

		try? WeTransfer.createTransfer(with: transfer, completion: { (result) in
			if case .failure(let error) = result {
				XCTFail(error.localizedDescription)
				return
			}

			try? WeTransfer.onlyAddFiles([file], to: transfer, completion: { (result) in
				if case .failure(let error) = result {
					XCTFail(error.localizedDescription)
					return
				}
				do {
					try WeTransfer.addUploadUrls(to: transfer, completion: { (result) in
						switch result {
						case .failure(let error):
							XCTFail(error.localizedDescription)
						case .success(let transfer):
							updatedFile = transfer.files.first
						}
						createdChunksExpectation.fulfill()
					})
				} catch {
					XCTFail(error.localizedDescription)
					createdChunksExpectation.fulfill()
				}
			})
		})

		waitForExpectations(timeout: 10) { _ in
			guard let file = updatedFile else {
				XCTFail("File not updated")
				return
			}
			XCTAssertNotNil(file.numberOfChunks)
			XCTAssertFalse(file.chunks.isEmpty)
			XCTAssertNotNil(file.multipartUploadIdentifier)
			XCTAssertEqual(file.numberOfChunks, Int(ceil(Double(file.filesize) / Double(Chunk.defaultChunkSize))))
		}
	}
}
