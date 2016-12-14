//
//  Response.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a response message to a request.
public protocol ResponseProtocol: MessageProtocol {
	/// A string which identifies the original request.
	var requestID: String { get }
}
