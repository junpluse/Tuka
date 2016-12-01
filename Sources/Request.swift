//
//  Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol RequestProtocol: MessageProtocol {
	associatedtype Response: ResponseProtocol

	var requestID: String { get }
}
