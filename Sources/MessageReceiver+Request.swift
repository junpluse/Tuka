//
//  MessageReceiver+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public enum RequestTimeoutResult<Request: RequestProtocol, Peer: PeerProtocol> {
	case success([Peer: Request.Response])
	case timedOut
}

extension MessageReceiverProtocol {
	public func observeResponses<T: RequestProtocol>(for request: T, from peers: [Peer], on queue: DispatchQueue, timeoutAfter interval: TimeInterval, handler: @escaping (RequestTimeoutResult<T, Peer>) -> Void) -> Disposable {
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

		disposable += observeMessages(T.Response.self, on: queue) { response, peer in
			guard peers.contains(peer), response.requestID == request.requestID else { return }
			responses.modify { $0[peer] = response }
			if responses.value.count == peers.count {
				handler(.success(responses.value))
				disposable.dispose()
			}
		}

		return disposable
	}

	public func observeResponses<T: RequestReceiptProtocol>(for receipt: T, on queue: DispatchQueue, timeoutAfter interval: TimeInterval, handler: @escaping (RequestTimeoutResult<T.Request, Peer>) -> Void) -> Disposable where T.Peer == Peer {
		return observeResponses(for: receipt.request, from: receipt.peers, on: queue, timeoutAfter: interval, handler: handler)
	}
}

extension MessageReceiverProtocol where Self: MessageSenderProtocol {
	public func respondToRequests<T: RequestResponderProtocol>(with responder: T, on queue: DispatchQueue) -> Disposable where T.Peer == Peer {
		return observeMessages(T.Request.self, on: queue) { request, peer in
			let response = responder.respond(to: request, from: peer)
			do {
				try self.send(response, to: [peer])
			} catch let error {
				print("[Tuka.MessageReceiverProtocol] failed to send response with error: \(error)")
			}
		}
	}

	public func respondToRequests<T: RequestProtocol>(_ request: T.Type, on queue: DispatchQueue, responder: @escaping (T, Peer) -> T.Response) -> Disposable {
		let responder = RequestResponder<T, Peer> { request, peer in
			return responder(request, peer)
		}
		return respondToRequests(with: responder, on: queue)
	}
}
