//
//  Secrets
//  WeTransferTests
//
//  Created by Pim Coumans on 02/07/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

struct Secrets {
	
	private enum SecretName: String {
		case productionKey = "production"
		case stagingKey = "staging"
		case stagingURL = "staging-url"
	}
	
	/* API keys are retrieved from 'Secrets.plist' which is used for running tests on travis.
	For local testing, please either manually add Secrets.plist with at least a 'production' key or replace the value below with your API key */
	static var productionKey: String {
		guard let value = value(for: .productionKey) else {
			fatalError("Production API key not found in Secrets.plist. Provide your own Secrets.plist with '\(SecretName.productionKey.rawValue)' or manually replace variable here")
		}
		return value
	}
	
	static var stagingKey: String {
		guard let value = value(for: .stagingKey) else {
			fatalError("Staging API key not found in Secrets.plist. Provide your own Secrets.plist with '\(SecretName.stagingKey.rawValue)' or manually replace variable here")
		}
		return value
	}
	
	static var stagingURL: URL {
		guard let value = value(for: .stagingURL), let url = URL(string: value) else {
			fatalError("Staging URL not found in Secrets.plist. Provide your own Secrets.plist with '\(SecretName.stagingURL.rawValue)' or manually replace variable here")
		}
		return url
	}
}

extension Secrets {
	private static var plistURL: URL? {
		return Bundle(for: TestConfiguration.shared.classForCoder).url(forResource: "Secrets", withExtension: "plist")
	}
	
	private static func value(for secret: SecretName) -> String? {
		guard let url = plistURL, let keysDictionary = NSDictionary(contentsOf: url) else {
			return nil
		}
		return keysDictionary[secret.rawValue] as? String
	}
}
