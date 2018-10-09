//
//  Transferable.swift
//  WeTransfer
//
//  Created by Pim Coumans on 04/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

/// Shared properties for both transfers and boards
public protocol Transferable {
	var identifier: String? { get }
	var files: [File] { get }
	var shortURL: URL? { get }
}
