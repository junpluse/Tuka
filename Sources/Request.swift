//
//  Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a request message.
public protocol RequestProtocol: MessageProtocol {
	associatedtype Response: ResponseProtocol

	/// A string which identifies the request between peers.
	var requestID: String { get }
}
