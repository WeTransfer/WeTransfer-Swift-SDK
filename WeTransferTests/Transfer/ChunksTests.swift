//
//  ChunksTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 28/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class ChunksTests: XCTestCase {

	override func setUp() {
		super.setUp()
		TestConfiguration.configure(environment: .production)
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
		var createdChunk: Chunk?

		let createdChunksExpectation = expectation(description: "Chunks are created")

		WeTransfer.createTransfer(with: transfer, completion: { (result) in
			if case .failure(let error) = result {
				XCTFail("Creating transfer failed: \(error)")
				createdChunksExpectation.fulfill()
				return
			}

			WeTransfer.add([file], to: transfer, completion: { (result) in
				if case .failure(let error) = result {
					XCTFail("Adding files failed: \(error)")
					createdChunksExpectation.fulfill()
					return
				}
				
				updatedFile = transfer.files.first
				guard let file = updatedFile else {
					XCTFail("File not added to transfer")
					createdChunksExpectation.fulfill()
					return
				}
				let operation = CreateChunkOperation(file: file, chunkIndex: 0)
				operation.onResult = { result in
					switch result {
					case .failure(let error):
						XCTFail("Creating chunk failed: \(error)")
					case .success(let chunk):
						createdChunk = chunk
					}
					createdChunksExpectation.fulfill()
				}
				WeTransfer.client.operationQueue.addOperation(operation)
			})
		})

		waitForExpectations(timeout: 10) { _ in
			guard let file = updatedFile else {
				XCTFail("File not created")
				return
			}
			XCTAssertNotNil(file.numberOfChunks, "File object doesn't have numberOfChunks")
			XCTAssertNotNil(file.multipartUploadIdentifier, "File object doesn't have numberOfChunks")
			XCTAssertEqual(file.numberOfChunks, Int(ceil(Double(file.filesize) / Double(Chunk.defaultChunkSize))), "File doesn't have correct number of chunks")
			XCTAssertNotNil(createdChunk, "Chunk not created")
		}
	}
}
