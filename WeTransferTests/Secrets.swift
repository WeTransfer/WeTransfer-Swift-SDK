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
	
	// FIXME: This retrieves the API keys from a plist that is used for running tests on travis, for local testing, please manually add Secrets.plist with at least a `production` key or replace the value below with your key
	static var productionKey: String {
		return value(for: .productionKey)
	}
	
	static var stagingKey: String {
		return value(for: .stagingKey)
	}
	
	static var stagingURL: URL {
		guard let url = URL(string: value(for: .stagingURL)) else {
			fatalError("Staging URL not available")
		}
		return url
	}
}

extension Secrets {
	private static var plistURL: URL? {
		return Bundle(for: TestConfiguration.shared.classForCoder).url(forResource: "Secrets", withExtension: "plist")
	}
	
	private static func value(for secret: SecretName) -> String {
		guard let url = plistURL, let keysDictionary = NSDictionary(contentsOf: url),
			let value = keysDictionary[secret.rawValue] as? String else {
				fatalError("'\(secret.rawValue)' key not available, provide your own Secrets.plist or manually define the keys in the Secrets struct")
		}
		return value
	}
}
