//
//  RequestReceipt.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/28.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import ReactiveSwift
import Result
import Foundation

/// Represents a receipt of request submission.
public final class RequestReceipt<Request: Tuka.Request, Sender: Tuka.MessageSender> {
	/// The submitted request.
	public let request: Request

	/// An array of peers that should receive the request.
	public let peers: [Sender.Peer]

	/// The sender who sent the request.
	public let sender: Sender

	/// The UUID which identifies the receipt.
	public let uuid: UUID

	/// Initializes a receipt with a request and an array of peers.
	///
	/// - Parameters:
	///   - request: A request to be sent.
	///   - peers: An array of peers that should receive the request.
	public init(request: Request, peers: [Sender.Peer], sender: Sender, uuid: UUID = UUID()) {
		self.request = request
		self.peers = peers
		self.sender = sender
		self.uuid = uuid
	}
}

extension RequestReceipt where Sender: MessageReceiver {
	public func responses() -> Signal<(Request.Response, Sender.Peer), NoError> {
		return sender.responses(to: request, from: peers)
	}
}

extension RequestReceipt: Equatable {
	public static func == (lhs: RequestReceipt, rhs: RequestReceipt) -> Bool {
		return lhs.uuid == rhs.uuid
	}
}

extension RequestReceipt: Hashable {
	public var hashValue: Int {
		return uuid.hashValue
	}
}
