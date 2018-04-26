//
//  Indentifiable.swift
//  WeTransfer Swift SDK
//
//  Created by Pim Coumans on 26/04/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public protocol Identifiable {
	var identifier: String? { get }
}
