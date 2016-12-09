//
//  MessageReceiver+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// A `ResponseCollectionEvent` value represents a event of response collection
/// that produced by a message receiver.
///
/// - received: Indicates that the response from a peer has been received.
/// - completed: Indicates that all responses from the peers has beed received.
/// - timedOut: Indicates that the receiver timed out the collection.
public enum ResponseCollectionEvent<Request: RequestProtocol, Peer: PeerProtocol> {
	case received(Request.Response, from: Peer)
	case completed([Peer: Request.Response])
	case timedOut
}

extension MessageReceiverProtocol {
	/// Collects responses to a request from peers.
	///
	/// - Parameters:
	///   - request: A request which the peers should be responded to.
	///   - peers: An array of peers who should respond to the request.
	///   - interval: An number of seconds to wait for the collection to complete.
	///   - queue: A dispatch queue which the closure should be added to.
	///   - handler: A closure to be executed when an event produced by the receiver.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func collectResponses<T: RequestProtocol>(to request: T, from peers: [Peer], timeoutAfter interval: TimeInterval, on queue: DispatchQueue, handler: @escaping (ResponseCollectionEvent<T, Peer>) -> Void) -> Disposable {
		let disposable = CompositeDisposable()
		if interval != .infinity {
			let timeout = DispatchWorkItem {
				handler(.timedOut)
				disposable.dispose()
			}
			queue.asyncAfter(deadline: .now() + interval, execute: timeout)
			disposable += { timeout.cancel() }
		}

		let responses = DispatchAtomic(Dictionary<Peer, T.Response>())

		disposable += subscribe(to: T.Response.self, on: queue) { response, peer in
			guard peers.contains(peer), response.requestID == request.requestID else { return }
			responses.modify { $0[peer] = response }
			handler(.received(response, from: peer))
			if responses.value.count == peers.count {
				handler(.completed(responses.value))
				disposable.dispose()
			}
		}

		return disposable
	}

	/// Collects responses to the request on a receipt.
	///
	/// - Parameters:
	///   - receipt: A receipt of the request which the peers should be responded to.
	///   - interval: An number of seconds to wait for the collection to complete.
	///   - queue: A dispatch queue which the closure should be added to.
	///   - handler: A closure to be executed when an event produced by the receiver.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func collectResponses<T: RequestReceiptProtocol>(with receipt: T, timeoutAfter interval: TimeInterval, on queue: DispatchQueue, handler: @escaping (ResponseCollectionEvent<T.Request, Peer>) -> Void) -> Disposable where T.Peer == Peer {
		return collectResponses(to: receipt.request, from: receipt.peers, timeoutAfter: interval, on: queue, handler: handler)
	}
}

extension MessageReceiverProtocol where Self: MessageSenderProtocol {
	/// Responds to requests with a responder.
	///
	/// - Parameters:
	///   - responder: A responder for the request.
	/// - Returns: A `Disposable` which can be used to remove the responder from the receiver.
	public func respond<T: RequestResponderProtocol>(with responder: T) -> Disposable where T.Peer == Peer {
		return subscribe(to: T.Request.self, on: responder.responseQueue) { request, peer in
			let response = responder.response(to: request, from: peer)
			do {
				try self.send(response, to: [peer])
			} catch let error {
				print("[Tuka.MessageReceiverProtocol] failed to send response with error: \(error)")
			}
		}
	}

	/// Responds to requests of the given type with a dispatch queue and a closure to add to the queue.
	///
	/// - Parameters:
	///   - requestType: A type of request which should be responded to.
	///   - queue: A dispatch queue which closure should be added to.
	///   - handler: A closure to be executed when the request is received.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func respond<T: RequestProtocol>(to requestType: T.Type, on queue: DispatchQueue, handler: @escaping (T, Peer) -> T.Response) -> Disposable {
		let responder = RequestResponder(queue: queue) { request, peer in
			return handler(request, peer)
		}
		return respond(with: responder)
	}
}
