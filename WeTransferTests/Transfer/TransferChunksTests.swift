//
//  TransferChunksTests
//  WeTransferTests
//
//  Created by Pim Coumans on 28/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class TransferChunksTests: BaseTestCase {

	func testChunkCreationRequest() {
		guard let fileURL = TestConfiguration.imageFileURL else {
			XCTFail("File not available")
			return
		}

		var updatedFile: File?
		var createdChunk: Chunk?

		let createdChunksExpectation = expectation(description: "Chunks are created")

		WeTransfer.createTransfer(saying: "Test Transfer", fileURLs: [fileURL]) { result in
			switch result {
			case .failure(let error):
				XCTFail("Creating transfer failed: \(error)")
				createdChunksExpectation.fulfill()
				return
			case .success(let transfer):
				updatedFile = transfer.files.first
				guard let file = updatedFile else {
					XCTFail("File not added to transfer")
					createdChunksExpectation.fulfill()
					return
				}
				let operation = CreateChunkOperation(container: transfer, file: file, chunkIndex: 0)
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
			XCTAssertNotNil(file.chunkSize, "File object must have a chunkSize")
			if let chunkSize = file.chunkSize {
				XCTAssertEqual(file.numberOfChunks, Int(ceil(Double(file.filesize) / Double(chunkSize))), "File doesn't have correct number of chunks")
			}
			XCTAssertNotNil(createdChunk, "Chunk not created")
		}
	}
}
