//
//  InitializationTests.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

class InitializationTests: XCTestCase {

	override func tearDown() {
		super.tearDown()
		TestConfiguration.resetConfiguration()
	}

	func testNotConfigured() {
		do {
			_ = try WeTransfer.client.createRequest(.createTransfer())
			XCTFail("Creation of request should've failed")
		} catch {
			XCTAssertEqual(error.localizedDescription, WeTransfer.Error.notConfigured.localizedDescription)
		}
	}

	func testConfigure() {
		TestConfiguration.configure(environment: .production)
		XCTAssertNotNil(WeTransfer.client.configuration?.apiKey, "APIKey needs to be set")
		XCTAssertNotNil(WeTransfer.client.configuration?.baseURL, "Base URL needs to be set")
		XCTAssertNotNil(WeTransfer.client.configuration?.clientIdentifier, "Client identifier is expected to be set")
	}
}
