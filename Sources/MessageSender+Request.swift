//
//  MessageSender+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

extension MessageSenderProtocol {
	/// Send a request message to peers.
	///
	/// - Parameters:
	///   - request: A request message to be sent.
	///   - peers: An array of peers that should receive the request.
	/// - Returns: A receipt of the submission.
	/// - Throws: An `Error` if sending the request could not be completed.
	/// - Note: Pass returned receipt to MessageReceiverProtocol.addObserver()
	///         to observe responses of the request.
	@discardableResult
	public func submit<T: RequestProtocol>(_ request: T, to peers: [Peer]) throws -> RequestReceipt<T, Self.Peer> {
		try send(request, to: peers)
		return RequestReceipt(request: request, peers: peers)
	}
}
