//
//  BaseTestCase.swift
//  WeTransfer
//
//  Created by Pim Coumans on 15/10/2018.
//  Copyright © 2018 WeTransfer. All rights reserved.
//

import XCTest
@testable import WeTransfer

open class BaseTestCase: XCTestCase {

    override open func setUp() {
		super.setUp()
		TestConfiguration.configure(environment: .production)
    }

    override open func tearDown() {
		super.tearDown()
		TestConfiguration.resetConfiguration()
    }

}
