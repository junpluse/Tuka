//
//  MessageReceiver+Request.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation

public enum ResponseObservationEvent<Request: RequestProtocol, Peer: PeerProtocol> {
	case received(Request.Response, from: Peer)
	case completed([Peer: Request.Response])
	case timedOut
}

extension MessageReceiverProtocol {
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

	public func addObserver<T: RequestReceiptProtocol>(forResponsesToRequestOn receipt: T, timeoutAfter interval: TimeInterval, on queue: DispatchQueue, handler: @escaping (ResponseObservationEvent<T.Request, Peer>) -> Void) -> Disposable where T.Peer == Peer {
		return addObserver(forResponsesTo: receipt.request, from: receipt.peers, timeoutAfter: interval, on: queue, handler: handler)
	}
}

extension MessageReceiverProtocol where Self: MessageSenderProtocol {
	public func add<T: RequestResponderProtocol>(_ responder: T) -> Disposable where T.Peer == Peer {
		return addObserver(for: T.Request.self, on: responder.responseQueue) { request, peer in
			let response = responder.respond(to: request, from: peer)
			do {
				try self.send(response, to: [peer])
			} catch let error {
				print("[Tuka.MessageReceiverProtocol] failed to send response with error: \(error)")
			}
		}
	}

	public func addResponder<T: RequestProtocol>(for requestType: T.Type, on queue: DispatchQueue, handler: @escaping (T, Peer) -> T.Response) -> Disposable {
		let responder = RequestResponder(queue: queue) { request, peer in
			return handler(request, peer)
		}
		return add(responder)
	}
}
