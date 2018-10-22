//
//  BoardChunksTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 01/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class BoardChunksTests: BaseTestCase {

	func testChunkCreationRequest() {
		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}

		var updatedFile: File?
		var createdChunk: Chunk?

		let createdChunksExpectation = expectation(description: "Chunks are created")

		let board = Board(name: "Test board", description: nil)
		WeTransfer.add([file], to: board) { (result) in
			switch result {
			case .failure(let error):
				XCTFail("Creating board failed: \(error)")
				createdChunksExpectation.fulfill()
				return
			case .success(let board):
				updatedFile = board.files.first
				guard let file = updatedFile else {
					XCTFail("File not added to transfer")
					createdChunksExpectation.fulfill()
					return
				}
				let operation = CreateChunkOperation(container: board, file: file, chunkIndex: 0)
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
			}
		}

		waitForExpectations(timeout: 10) { _ in
			guard let file = updatedFile else {
				XCTFail("File not created")
				return
			}
			XCTAssertNotNil(file.numberOfChunks, "File object doesn't have numberOfChunks")
			XCTAssertNotNil(file.multipartUploadIdentifier, "File object doesn't have a multipart upload identifier")
			XCTAssertEqual(file.numberOfChunks, Int(ceil(Double(file.filesize) / Double(file.chunkSize ?? Chunk.defaultChunkSize))), "File doesn't have correct number of chunks")
			XCTAssertNotNil(createdChunk, "Chunk not created")
		}
	}
}
