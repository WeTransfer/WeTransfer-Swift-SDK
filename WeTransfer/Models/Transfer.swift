//
//  Transfer.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public class Transfer: Identifiable, Encodable {
	public private(set) var identifier: String?
	
	public struct Item: Identifiable, Encodable {
		public let fileURL: URL
		public private(set) var identifier: String?
		public private(set) var uploaded: Bool = false
		
		public init(fileURL: URL) {
			self.fileURL = fileURL
		}
	}
	
	
	public let name: String
	public let description: String?
	
	public private(set) var items: [Item] = []
	
	public private(set) var shortURL: URL?
	
	public init(name: String, description: String?, items: [Item] = []) {
		self.name = name
		self.description = description
		self.items = items
	}
}

extension Transfer {
	func update(with response: WeTransfer.CreateTransferResponse) {
		identifier = "\(response.id)"
		shortURL = response.shortenedUrl
	}
}
