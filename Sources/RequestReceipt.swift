//
//  RequestReceipt.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/28.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a receipt of request submission.
public protocol RequestReceiptProtocol {
	associatedtype Request: RequestProtocol
	associatedtype Peer: PeerProtocol

	/// The submitted request.
	var request: Request { get }

	/// An array of peers that should receive the request.
	var peers: [Peer] { get }
}

/// A simple class that implements `RequestReceiptProtocol`.
public final class RequestReceipt<Request: RequestProtocol, Peer: PeerProtocol>: RequestReceiptProtocol {
	public let request: Request
	public let peers: [Peer]

	/// Initializes a receipt with a request and an array of peers.
	///
	/// - Parameters:
	///   - request: A request to be sent.
	///   - peers: An array of peers that should receive the request.
	public init(request: Request, peers: [Peer]) {
		self.request = request
		self.peers = peers
	}

	/// Initializes a receipt which wraps the given receipt.
	///
	/// - Parameters:
	///   - receipt: A receipt to be wrapped.
	public init<T: RequestReceiptProtocol>(_ receipt: T) where T.Request == Request, T.Peer == Peer {
		self.request = receipt.request
		self.peers = receipt.peers
	}
}
