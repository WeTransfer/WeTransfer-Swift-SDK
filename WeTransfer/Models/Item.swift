//
//  Item.swift
//  WeTransfer
//
//  Created by Pim Coumans on 06/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public protocol Item {
    
    /// Server-side identifier when file is added to the transfer or board on the server
    var identifier: String? { get }
    
}
