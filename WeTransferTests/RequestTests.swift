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
		let baseURLString = "https://dev.wetransfer.com/v1/"
		let baseURL = URL(string: baseURLString)!

		let authorizeEndpoint: APIEndpoint = .authorize()
		XCTAssertEqual(authorizeEndpoint.method, .post)
		XCTAssertEqual(authorizeEndpoint.url(with: baseURL).absoluteString, baseURLString + "authorize")

		let createTransferEndpoint: APIEndpoint = .createTransfer()
		XCTAssertEqual(createTransferEndpoint.method, .post)
		XCTAssertEqual(createTransferEndpoint.url(with: baseURL).absoluteString, baseURLString + "transfers")

		let itemIdentifier = "1234567890"
		let addItemsTransferEndpoint: APIEndpoint = .addItems(transferIdentifier: itemIdentifier)
		XCTAssertEqual(addItemsTransferEndpoint.method, .post)
		XCTAssertEqual(addItemsTransferEndpoint.url(with: baseURL).absoluteString, baseURLString + "transfers/\(itemIdentifier)/items")

		let fileIdentifier = UUID().uuidString
		let chunkIndex = 5
		let multipartIdentifier = UUID().uuidString
		let requestUploadURLEndpoint: APIEndpoint = .requestUploadURL(fileIdentifier: fileIdentifier, chunkIndex: chunkIndex, multipartIdentifier: multipartIdentifier)
		XCTAssertEqual(requestUploadURLEndpoint.method, .get)
		XCTAssertEqual(requestUploadURLEndpoint.url(with: baseURL).absoluteString, baseURLString + "files/\(fileIdentifier)/uploads/\(chunkIndex + 1)/\(multipartIdentifier)")

		let completeUploadEndpoint: APIEndpoint = .completeUpload(fileIdentifier: fileIdentifier)
		XCTAssertEqual(completeUploadEndpoint.method, .post)
		XCTAssertEqual(completeUploadEndpoint.url(with: baseURL).absoluteString, baseURLString + "files/\(fileIdentifier)/uploads/complete")
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
