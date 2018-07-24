//
//  TestConfiguration.swift
//  WeTransferTests
//
//  Created by Pim Coumans on 22/05/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation
@testable import WeTransfer

final class TestConfiguration: NSObject {

	enum Environment {
		case production
		case staging
	}

	static func configure(environment: Environment) {
		let configuration: WeTransfer.Configuration

		switch environment {
		case .production:
			configuration = WeTransfer.Configuration(apiKey: Secrets.productionKey)
		case .staging:
			configuration = WeTransfer.Configuration(apiKey: Secrets.stagingKey, baseURL: Secrets.stagingURL)
		}
		WeTransfer.configure(with: configuration)
	}

	static func fakeAuthorize() {
		WeTransfer.client.authenticator.updateBearer("Fake.Tokens.Gonna-Fake")
	}

	static func resetConfiguration() {
		WeTransfer.client.apiKey = nil
		WeTransfer.client.authenticator.updateBearer(nil)
	}
}

extension TestConfiguration {
	static let shared = TestConfiguration()

	final class var imageFileURL: URL? {
		return Bundle(for: self.shared.classForCoder).url(forResource: "image", withExtension: "jpg")
	}

	final class var fileModel: File? {
		guard let imageFileURL = imageFileURL else {
			return nil
		}
		return try? File(url: imageFileURL)
	}
	
	final class var smallImageFileURL: URL? {
		return Bundle(for: self.shared.classForCoder).url(forResource: "smallImage", withExtension: "jpg")
	}
	
	final class var smallFileModel: File? {
		guard let imageFileURL = smallImageFileURL else {
			return nil
		}
		return try? File(url: imageFileURL)
	}
}
