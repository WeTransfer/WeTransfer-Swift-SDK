//
//  URLItem.swift
//  WeTransfer
//
//  Created by Pim Coumans on 06/11/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import Foundation

public struct URLItem: Item, Decodable {
    
    let url: URL
    
    public private(set) var identifier: String?
}
