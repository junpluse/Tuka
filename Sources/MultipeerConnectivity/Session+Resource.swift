//
//  Session+Resource.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public enum ResourceTransferEvent<Request: ResourceRequestProtocol> {
	case started(Request, Session.Peer, Progress?)
	case finished(Request, Session.Peer, URL)
	case failed(Request, Session.Peer, Error)
}

public final class ResourceTransferOperation<Request: ResourceRequestProtocol>: RequestReceiptProtocol {
	public typealias Peer = Session.Peer
	public typealias Event = ResourceTransferEvent<Request>

	public let request: Request
	public let peers: [Peer]

	fileprivate let disposable = CompositeDisposable()
	fileprivate let eventObserver = CompositeObserver<Event>()

	fileprivate init(request: Request, peers: [Peer]) {
		self.request = request
		self.peers = peers
	}

	public func addEventObserver(on queue: DispatchQueue, action: @escaping (ResourceTransferEvent<Request>) -> Void) -> Disposable {
		let observer = DispatchObserver(queue: queue, action: action)
		return eventObserver.add(observer)
	}
}

extension ResourceTransferOperation: Disposable {
	public var isDisposed: Bool {
		return disposable.isDisposed
	}

	public func dispose() {
		disposable.dispose()
	}
}

extension Session {
	public func submit<T: ResourceRequestProtocol>(_ resourceRequest: T, withResourceAt localURL: URL, to peers: [MCPeerID]) throws -> ResourceTransferOperation<T> {
		try send(resourceRequest, to: peers)

		let receipt = ResourceTransferOperation(request: resourceRequest, peers: peers)
		let transferQueue = DispatchQueue(label: "com.junpluse.Tuka.Session.ResourceTransferQueue")

		peers.forEach { peer in
			let item = DispatchWorkItem { [mcSession] in
				let semaphore = DispatchSemaphore(value: 0)
				let progress = mcSession.sendResource(at: localURL, withName: resourceRequest.resourceName, toPeer: peer) { error in
					if let error = error {
						receipt.eventObserver.observe(.failed(resourceRequest, peer, error))
					} else {
						receipt.eventObserver.observe(.finished(resourceRequest, peer, localURL))
					}
					semaphore.signal()
				}
				receipt.disposable += { progress?.cancel() }
				receipt.eventObserver.observe(.started(resourceRequest, peer, progress))
				semaphore.wait()
			}
			receipt.disposable += { item.cancel() }
			transferQueue.async(execute: item)
		}

		return receipt
	}

	public func submit(resourceAt localURL: URL, to peers: [MCPeerID]) throws -> ResourceTransferOperation<ResourceRequest> {
		let request = ResourceRequest()
		return try submit(request, withResourceAt: localURL, to: peers)
	}
}

extension Session {
	public func addResponder<T: ResourceRequestProtocol>(for resourceRequestType: T.Type, on queue: DispatchQueue, action: @escaping (_ event: ResourceTransferEvent<T>, _ send: @escaping (_ response: T.Response) throws -> Void) -> Void) -> Disposable {
		let disposable = CompositeDisposable()

		let responseQueue = DispatchQueue(label: "com.junpluse.Tuka.Session.ResourceRequestResponderQueue")
		let responder = RequestResponder<T, MCPeerID>(queue: responseQueue) { request, peer, send in
			let sessionEventDisposable = CompositeDisposable()

			let sendAndDispose: (T.Response) throws -> Void = { response in
				try send(response)
				sessionEventDisposable.dispose()
			}

			sessionEventDisposable += self.addSessionEventObserver(on: queue) { event in
				switch event {
				case .didStartReceivingResource(let name, let from, let progress):
					guard name == request.resourceName, from == peer else { return }
					action(.started(request, peer, progress), sendAndDispose)
				case .didFinishReceivingResource(let name, let from, let localURL, let error):
					guard name == request.resourceName, from == peer else { return }
					if let error = error {
						action(.failed(request, peer, error), sendAndDispose)
					} else {
						action(.finished(request, peer, localURL), sendAndDispose)
					}
					sessionEventDisposable.dispose()
				default:
					break
				}
			}
			disposable += sessionEventDisposable
		}

		disposable += addResponder(responder)

		return disposable
	}
}
