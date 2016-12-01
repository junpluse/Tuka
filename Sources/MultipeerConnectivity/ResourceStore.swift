//
//  ResourceStore.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/24.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol ResourceStoreProtocol {
	associatedtype Request: ResourceRequestProtocol
	associatedtype Peer: PeerProtocol

	func storeResource(at fileURL: URL, with request: Request, from peer: Peer) throws
}

public struct ResourceStore<Request: ResourceRequestProtocol, Peer: PeerProtocol>: ResourceStoreProtocol {
	private let _storeResource: (URL, Request, Peer) throws -> Void

	public init<T: ResourceStoreProtocol>(_ base: T) where T.Request == Request, T.Peer == Peer {
		_storeResource = { fileURL, request, peer in
			try base.storeResource(at: fileURL, with: request, from: peer)
		}
	}

	public func storeResource(at fileURL: URL, with request: Request, from peer: Peer) throws {
		try _storeResource(fileURL, request, peer)
	}
}
