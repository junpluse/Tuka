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

extension MessageSenderProtocol where Self: MessageReceiverProtocol {
	/// Send a request message to peers then observe responses for it.
	///
	/// - Parameters:
	///   - request: A request message to be sent.
	///   - peers: An array of peers that should receive the request.
	///   - interval: An number of seconds for waiting to complete.
	///   - queue: A dispatch queue which the closure should be added to.
	///   - observer: A closure to be executed when an response event produced by the receiver.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	/// - Throws: An `Error` if sending the request could not be completed.
	/// - Note: This method is a combination of MessageSenderProtocol.submit(_:to:) and
	///         MessageReceiverProtocol.addObserver(for:timeoutAfter:on:action:).
	public func submit<T: RequestProtocol>(_ request: T, to peers: [Peer], timeoutAfter interval: TimeInterval, on queue: DispatchQueue, observer: @escaping (_ event: ResponseEvent<T, Peer>) -> Void) throws -> Disposable {
		let receipt = try submit(request, to: peers)
		return addObserver(for: receipt, timeoutAfter: interval, on: queue, action: observer)
	}
}
