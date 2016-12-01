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

	func respond(to request: Request, from peer: Peer) -> Request.Response
}

public struct RequestResponder<Request: RequestProtocol, Peer: PeerProtocol>: RequestResponderProtocol {
	private let _action: (Request, Peer) -> Request.Response

	public init(_ action: @escaping (Request, Peer) -> Request.Response) {
		_action = action
	}

	public init<T: RequestResponderProtocol>(_ base: T) where T.Request == Request, T.Peer == Peer {
		_action = { request, peer in
			return base.respond(to: request, from: peer)
		}
	}

	public func respond(to request: Request, from peer: Peer) -> Request.Response {
		return _action(request, peer)
	}
}
