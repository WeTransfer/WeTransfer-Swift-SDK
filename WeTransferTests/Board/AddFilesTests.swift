//
//  AddFilesTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 01/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class AddFilesTests: BaseTestCase {

	func testAddingFilesToBoardModel() {
		
		let transfer = Board(name: "Test Transfer", description: nil)
		guard let file = TestConfiguration.fileModel else {
			XCTFail("Could not create file model")
			return
		}

		transfer.add([file])
		XCTAssertTrue(transfer.files.contains(file))
		XCTAssertEqual(transfer.files.count, 1)

		transfer.add([file])
		XCTAssertEqual(transfer.files.count, 1)
	}

	func testFileModel() {
		guard TestConfiguration.imageFileURL != nil else {
			XCTFail("Test image not found")
			return
		}

		guard let file = TestConfiguration.fileModel else {
			XCTFail("Could not create file model")
			return
		}

		XCTAssertNil(file.identifier)
		XCTAssertFalse(file.isUploaded)
		XCTAssertNil(file.numberOfChunks)
		XCTAssertNil(file.multipartUploadIdentifier)
		XCTAssertEqual(file.filesize, 1200480, "File size not equal")
	}

	func testAddFilesRequest() {
		let board = Board(name: "Test Transfer", description: nil)

		guard let file = TestConfiguration.fileModel else {
			XCTFail("File not available")
			return
		}

		let addedFilesExpectation = expectation(description: "Files are added")
		
		WeTransfer.add([file], to: board, completion: { (result) in
			if case .failure(let error) = result {
				XCTFail("Add files to transfer failed: \(error)")
			}
			addedFilesExpectation.fulfill()
		})

		waitForExpectations(timeout: 10) { _ in
			XCTAssertFalse(board.files.isEmpty)
			for file in board.files {
				XCTAssertNotNil(file.identifier)
				XCTAssertFalse(file.isUploaded)
			}
		}
	}
	
	func testMulitpleFileRequests() {
		let board = Board(name: "Test Transfer", description: nil)
		
		guard let file = TestConfiguration.fileModel, let smallFile = TestConfiguration.smallFileModel else {
			XCTFail("File not available")
			return
		}
		
		let addedFirstFileExpectation = expectation(description: "First file was added")
		let addedSecondFileExpectation = expectation(description: "Second file was added")
		
		WeTransfer.createExternalBoard(board) { result in
			if case .failure(let error) = result {
				XCTFail("Create transfer failed: \(error)")
				return
			}
			
			var firstFileCompleted = false
			
			WeTransfer.add([file], to: board, completion: { (result) in
				if case .failure(let error) = result {
					XCTFail("Add files to transfer failed: \(error)")
					return
				}
				firstFileCompleted = true
				addedFirstFileExpectation.fulfill()
			})
			
			// Do the small file second and expect it to be completed after the first file completes
			WeTransfer.add([smallFile], to: board, completion: { (result) in
				if case .failure(let error) = result {
					XCTFail("Add files to transfer failed: \(error)")
					return
				}
				XCTAssertEqual(board.files.count, 2)
				XCTAssertTrue(firstFileCompleted)
				addedSecondFileExpectation.fulfill()
			})
		}
		
		waitForExpectations(timeout: 10) { _ in
			XCTAssertFalse(board.files.isEmpty)
			for file in board.files {
				XCTAssertNotNil(file.identifier)
				XCTAssertFalse(file.isUploaded)
			}
		}
	}
}
