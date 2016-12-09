//
//  RequestResponder.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/24.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public protocol RequestResponderProtocol {
	associatedtype Request: RequestProtocol
	associatedtype Peer: PeerProtocol

	var responseQueue: DispatchQueue { get }

	func response(to request: Request, from peer: Peer) -> Request.Response
}

public struct RequestResponder<Request: RequestProtocol, Peer: PeerProtocol>: RequestResponderProtocol {
	private let _queue: DispatchQueue
	private let _action: (Request, Peer) -> Request.Response

	public init(queue: DispatchQueue, action: @escaping (Request, Peer) -> Request.Response) {
		_queue = queue
		_action = action
	}

	public init<T: RequestResponderProtocol>(_ responder: T) where T.Request == Request, T.Peer == Peer {
		_queue = responder.responseQueue
		_action = { request, peer in
			return responder.response(to: request, from: peer)
		}
	}

	public var responseQueue: DispatchQueue {
		return _queue
	}

	public func response(to request: Request, from peer: Peer) -> Request.Response {
		return _action(request, peer)
	}
}
