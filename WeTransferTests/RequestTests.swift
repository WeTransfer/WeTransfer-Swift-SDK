//
//  SimpleTransferTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

final class RequestTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		TestConfiguration.resetConfiguration()
	}

	func testEndpoints() {
		let baseURLString = "https://dev.wetransfer.com/v2/"
		let baseURL = URL(string: baseURLString)!

		let authorizeEndpoint: APIEndpoint = .authorize()
		XCTAssertEqual(authorizeEndpoint.method, .post)
		XCTAssertEqual(authorizeEndpoint.url(with: baseURL).absoluteString, baseURLString + "authorize")

		let createTransferEndpoint: APIEndpoint = .createTransfer()
		XCTAssertEqual(createTransferEndpoint.method, .post)
		XCTAssertEqual(createTransferEndpoint.url(with: baseURL).absoluteString, baseURLString + "transfers")
		
		let createBoardEndpoint: APIEndpoint = .createBoard()
		XCTAssertEqual(createBoardEndpoint.method, .post)
		XCTAssertEqual(createBoardEndpoint.url(with: baseURL).absoluteString, baseURLString + "boards")

		let transferIdentifier = UUID().uuidString
		let boardIdentifier = UUID().uuidString
		let fileIdentifier = UUID().uuidString
		let chunkIndex = 5
		let multipartIdentifier = UUID().uuidString
		
		let addFilesTransferEndpoint: APIEndpoint = .addFiles(boardIdentifier: boardIdentifier)
		XCTAssertEqual(addFilesTransferEndpoint.method, .post)
		XCTAssertEqual(addFilesTransferEndpoint.url(with: baseURL).absoluteString, baseURLString + "boards/\(boardIdentifier)/files")
		
		let requestTransferUploadURLEndpoint: APIEndpoint = .requestTransferUploadURL(transferIdentifier: transferIdentifier, fileIdentifier: fileIdentifier, chunkIndex: chunkIndex)
		XCTAssertEqual(requestTransferUploadURLEndpoint.method, .get)
		XCTAssertEqual(requestTransferUploadURLEndpoint.url(with: baseURL).absoluteString, baseURLString + "transfers/\(transferIdentifier)/files/\(fileIdentifier)/upload-url/\(chunkIndex + 1)")
		
		let requestBoardUploadURLEndpoint: APIEndpoint = .requestBoardUploadURL(boardIdentifier: boardIdentifier, fileIdentifier: fileIdentifier, chunkIndex: chunkIndex, multipartIdentifier: multipartIdentifier)
		XCTAssertEqual(requestBoardUploadURLEndpoint.method, .get)
		XCTAssertEqual(requestBoardUploadURLEndpoint.url(with: baseURL).absoluteString, baseURLString + "boards/\(boardIdentifier)/files/\(fileIdentifier)/upload-url/\(chunkIndex + 1)/\(multipartIdentifier)")

		let completeTransferFileUploadEndpoint: APIEndpoint = .completeTransferFileUpload(transferIdentifier: transferIdentifier, fileIdentifier: fileIdentifier)
		XCTAssertEqual(completeTransferFileUploadEndpoint.method, .put)
		XCTAssertEqual(completeTransferFileUploadEndpoint.url(with: baseURL).absoluteString, baseURLString + "transfers/\(transferIdentifier)/files/\(fileIdentifier)/upload-complete")
		
		let completeBoardFileUploadEndpoint: APIEndpoint = .completeBoardFileUpload(boardIdentifier: boardIdentifier, fileIdentifier: fileIdentifier)
		XCTAssertEqual(completeBoardFileUploadEndpoint.method, .put)
		XCTAssertEqual(completeBoardFileUploadEndpoint.url(with: baseURL).absoluteString, baseURLString + "boards/\(boardIdentifier)/files/\(fileIdentifier)/upload-complete")
		
		let finlizeTransferEndpoint: APIEndpoint = .finalizeTransfer(transferIdentifier: transferIdentifier)
		XCTAssertEqual(finlizeTransferEndpoint.method, .put)
		XCTAssertEqual(finlizeTransferEndpoint.url(with: baseURL).absoluteString, baseURLString + "transfers/\(transferIdentifier)/finalize")
	}

	func testUnconfiguredRequestCreation() {
		do {
			_ = try WeTransfer.client.createRequest(.createTransfer())
			XCTFail("Request creation should have failed with 'not configured' error")
		} catch {
			XCTAssertEqual(error.localizedDescription, WeTransfer.Error.notConfigured.localizedDescription)
		}
	}

	func testRequestCreation() {
		TestConfiguration.configure(environment: .production)
		TestConfiguration.fakeAuthorize()
		let client = WeTransfer.client
		
		do {
			_ = try client.createRequest(.createTransfer())
		} catch {
			XCTFail(error.localizedDescription)
		}
	}

}
