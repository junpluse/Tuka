//
//  MessageReceiver+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

/// A `ResponseObservationEvent` value represents a event of response observation
/// that produced by the message receiver.
///
/// - received: Indicates that the response from a peer has been received.
/// - completed: Indicates that all responses from the peers has beed received.
/// - timedOut: Indicates that the receiver timed out the observation of responses.
public enum ResponseObservationEvent<Request: RequestProtocol, Peer: PeerProtocol> {
	case received(Request.Response, from: Peer)
	case completed([Peer: Request.Response])
	case timedOut
}

extension MessageReceiverProtocol {
	/// Adds a handler that observe responses to the request.
	///
	/// - Parameters:
	///   - request: A request for responses which should be observed.
	///   - peers: An array of peers who should respond the request.
	///   - interval: An number of seconds to wait for the observation to complete.
	///   - queue: A dispatch queue to which closure should be added.
	///   - handler: A closure to be executed when an observation event produced by the receiver.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func addObserver<T: RequestProtocol>(forResponsesTo request: T, from peers: [Peer], timeoutAfter interval: TimeInterval, on queue: DispatchQueue, handler: @escaping (ResponseObservationEvent<T, Peer>) -> Void) -> Disposable {
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

		disposable += addObserver(for: T.Response.self, on: queue) { response, peer in
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

	/// Adds a handler that observe responses to the request on the given receipt.
	///
	/// - Parameters:
	///   - receipt: A receipt of the request for the responses which should be observed.
	///   - interval: An number of seconds to wait for the observation to complete.
	///   - queue: A dispatch queue to which closure should be added.
	///   - handler: A closure to be executed when the observation is completed or timed out.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func addObserver<T: RequestReceiptProtocol>(forResponsesToRequestOn receipt: T, timeoutAfter interval: TimeInterval, on queue: DispatchQueue, handler: @escaping (ResponseObservationEvent<T.Request, Peer>) -> Void) -> Disposable where T.Peer == Peer {
		return addObserver(forResponsesTo: receipt.request, from: receipt.peers, timeoutAfter: interval, on: queue, handler: handler)
	}
}

extension MessageReceiverProtocol where Self: MessageSenderProtocol {
	/// Adds a responder for the request.
	///
	/// - Parameters:
	///   - responder: A responder for the request.
	/// - Returns: A `Disposable` which can be used to remove the responder from the receiver.
	public func addResponder<T: RequestResponderProtocol>(_ responder: T) -> Disposable where T.Peer == Peer {
		return addObserver(for: T.Request.self, on: responder.responseQueue) { request, peer in
			let response = responder.respond(to: request, from: peer)
			do {
				try self.send(response, to: [peer])
			} catch let error {
				print("[Tuka.MessageReceiverProtocol] failed to send response with error: \(error)")
			}
		}
	}

	/// Adds a handler that respond to requests of the given type.
	///
	/// - Parameters:
	///   - requestType: A type of request which should be responded to.
	///   - queue: A dispatch queue to which closure should be added.
	///   - handler: A closure to be executed when the request is received.
	/// - Returns: A `Disposable` which can be used to stop the invocation of the closure.
	public func addResponder<T: RequestProtocol>(for requestType: T.Type, on queue: DispatchQueue, handler: @escaping (T, Peer) -> T.Response) -> Disposable {
		let responder = RequestResponder(queue: queue) { request, peer in
			return handler(request, peer)
		}
		return addResponder(responder)
	}
}
