//
//  RequestReceipt.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/28.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol RequestReceiptProtocol {
	associatedtype Request: RequestProtocol
	associatedtype Peer: PeerProtocol

	var request: Request { get }
	var peers: [Peer] { get }
}

public final class RequestReceipt<Request: RequestProtocol, Peer: PeerProtocol>: RequestReceiptProtocol {
	public let request: Request
	public let peers: [Peer]

	public init(request: Request, peers: [Peer]) {
		self.request = request
		self.peers = peers
	}

	public init<T: RequestReceiptProtocol>(_ base: T) where T.Request == Request, T.Peer == Peer {
		self.request = base.request
		self.peers = base.peers
	}
}
