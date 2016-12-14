//
//  MessageReceiver+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// A `ResponseEvent` value represents a event while observing responses.
///
/// - received: Indicates that the response from a peer has been received.
/// - completed: Indicates that all responses from the peers has beed received.
/// - timedOut: Indicates that the receiver timed out the observation.
public enum ResponseEvent<Request: RequestProtocol, Peer: PeerProtocol> {
	case received(Request.Response, from: Peer)
	case completed([Peer: Request.Response])
	case timedOut
}

extension MessageReceiverProtocol {
	/// Adds an observer for responses to the request on a receipt.
	///
	/// - Parameters:
	///   - request: A request which the peers should be responded to.
	///   - peers: An array of peers who should respond to the request.
	///   - interval: An number of seconds for waiting to complete.
	///   - queue: A dispatch queue which the closure should be added to.
	///   - action: A closure to be executed when an event produced by the receiver.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func addObserver<T: RequestReceiptProtocol>(for receipt: T, timeoutAfter interval: TimeInterval, on queue: DispatchQueue, action: @escaping (ResponseEvent<T.Request, Peer>) -> Void) -> Disposable where T.Peer == Peer {
		let disposable = CompositeDisposable()

		if interval != .infinity {
			let timeout = DispatchWorkItem {
				action(.timedOut)
				disposable.dispose()
			}
			queue.asyncAfter(deadline: .now() + interval, execute: timeout)
			disposable += { timeout.cancel() }
		}

		let responses = DispatchAtomic(Dictionary<Peer, T.Request.Response>())

		disposable += addObserver(for: T.Request.Response.self, on: queue) { response, peer in
			guard
				receipt.peers.contains(peer),
				response.requestID == receipt.request.requestID else {
					return
			}
			responses.modify { $0[peer] = response }
			action(.received(response, from: peer))
			if responses.value.count == receipt.peers.count {
				action(.completed(responses.value))
				disposable.dispose()
			}
		}

		return disposable
	}
}

extension MessageReceiverProtocol where Self: MessageSenderProtocol {
	/// Adds a responder for requests received by the receiver.
	///
	/// - Parameters:
	///   - responder: A responder that responds to requests received by the receiver.
	/// - Returns: A `Disposable` which can be used to remove the responder from the receiver.
	public func addResponder<T: RequestResponderProtocol>(_ responder: T) -> Disposable where T.Peer == Peer {
		return addObserver(for: T.Request.self, on: responder.responseQueue) { request, peer in
			let response = responder.response(to: request, from: peer)
			do {
				try self.send(response, to: [peer])
			} catch let error {
				print("[Tuka.MessageReceiverProtocol] failed to send response with error: \(error)")
			}
		}
	}

	/// Adds a responder for requests of the given type with a dispatch queue and a closure to add to the queue.
	///
	/// - Parameters:
	///   - requestType: A type of request which should be responded to.
	///   - queue: A dispatch queue to which closure should be added.
	///   - action: A closure to be executed when the request is received.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func addResponder<T: RequestProtocol>(for requestType: T.Type, on queue: DispatchQueue, action: @escaping (T, Peer) -> T.Response) -> Disposable {
		let responder = RequestResponder(queue: queue) { request, peer in
			return action(request, peer)
		}
		return addResponder(responder)
	}
}
