//
//  RequestResponder.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/24.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// Represents a responder to requests of a type.
public protocol RequestResponderProtocol {
	associatedtype Request: RequestProtocol
	associatedtype Peer: PeerProtocol

	/// A dispatch queue to which `response()` method should be invoked on.
	var responseQueue: DispatchQueue { get }

	/// Returns a response to a request from a peer.
	///
	/// - Parameters:
	///   - request: A request which should be responded to.
	///   - peer: A peer which sent the request.
	/// - Returns: A response to the request.
	func response(to request: Request, from peer: Peer) -> Request.Response
}

/// A struct that implements `RequestResponderProtocol` using a queue and a closure,
/// or another one that conforms `RequestResponderProtocol` to be wrapped.
public struct RequestResponder<Request: RequestProtocol, Peer: PeerProtocol>: RequestResponderProtocol {
	private let _queue: DispatchQueue
	private let _action: (Request, Peer) -> Request.Response

	/// Initializes a request responder which respond to requests using the given closure.
	///
	/// - Parameters:
	///   - queue: A dispatch queue to which `response()` method should be invoked on.
	///   - action: A closure to which be executed to generate a response to a request.
	public init(queue: DispatchQueue, action: @escaping (Request, Peer) -> Request.Response) {
		_queue = queue
		_action = action
	}

	/// Initializes a request responder which wraps the given sender.
	///
	/// - Parameter sender: A sender to be wrapped.
	public init<T: RequestResponderProtocol>(_ responder: T) where T.Request == Request, T.Peer == Peer {
		_queue = responder.responseQueue
		_action = { request, peer in
			return responder.response(to: request, from: peer)
		}
	}

	/// A dispatch queue to which `response()` method should be invoked on.
	public var responseQueue: DispatchQueue {
		return _queue
	}

	/// Returns a response to a request from a peer.
	///
	/// - Parameters:
	///   - request: A request which should be responded to.
	///   - peer: A peer which sent the request.
	/// - Returns: A response to the request.
	public func response(to request: Request, from peer: Peer) -> Request.Response {
		return _action(request, peer)
	}
}
