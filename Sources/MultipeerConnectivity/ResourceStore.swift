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

	var storeQueue: DispatchQueue { get }

	func storeResource(at fileURL: URL, with request: Request, from peer: Peer) throws
}

public struct ResourceStore<Request: ResourceRequestProtocol, Peer: PeerProtocol>: ResourceStoreProtocol {
	private let _queue: DispatchQueue
	private let _action: (URL, Request, Peer) throws -> Void

	public init(queue: DispatchQueue, action: @escaping (URL, Request, Peer) throws -> Void) {
		_queue = queue
		_action = action
	}

	public init<T: ResourceStoreProtocol>(_ store: T) where T.Request == Request, T.Peer == Peer {
		_queue = store.storeQueue
		_action = { fileURL, request, peer in
			try store.storeResource(at: fileURL, with: request, from: peer)
		}
	}

	public var storeQueue: DispatchQueue {
		return _queue
	}

	public func storeResource(at fileURL: URL, with request: Request, from peer: Peer) throws {
		try _action(fileURL, request, peer)
	}
}
