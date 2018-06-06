//
//  TestConfiguration.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
@testable import WeTransfer

class TestConfiguration: NSObject {

	enum Environment {
		case production
		case staging
	}

	static func configure(environment: Environment) {
		let configuration: WeTransfer.Configuration

		switch environment {
			configuration = WeTransfer.Configuration(APIKey: "{YOUR_API_KEY_HERE}")
		case .production:
		case .staging:
			configuration = WeTransfer.Configuration(APIKey: "{YOUR_API_KEY_HERE}", baseURL: URL(string: "https://developers.wetransferbeta.com/v1"))
		}
		WeTransfer.configure(with: configuration)
	}

	static func fakeAuthorize() {
		WeTransfer.client.authenticationBearer = "Fake.Tokens.Gonna-Fake"
	}

	static func resetConfiguration() {
		WeTransfer.client.apiKey = nil
		WeTransfer.client.authenticationBearer = nil
	}
}

extension TestConfiguration {
	static let shared = TestConfiguration()

	class var imageFileURL: URL? {
		return Bundle(for: self.shared.classForCoder).url(forResource: "image", withExtension: "jpg")
	}

	class var fileModel: File? {
		guard let imageFileURL = imageFileURL else {
			return nil
		}
		return File(url: imageFileURL)
	}
}
