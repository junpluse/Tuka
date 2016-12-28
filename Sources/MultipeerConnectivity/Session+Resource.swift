//
//  Session+Resource.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public final class ResourceRequestReceipt<Request: ResourceRequestProtocol>: RequestReceiptProtocol {
	public typealias Peer = Session.Peer
	public typealias Event = ResourceEvent<Request>

	public let request: Request
	public let peers: [Peer]

	fileprivate let disposable = CompositeDisposable()
	fileprivate let eventObserver = CompositeObserver<Event>()

	fileprivate init(request: Request, peers: [Peer]) {
		self.request = request
		self.peers = peers
	}
}

extension ResourceRequestReceipt: ResourceEventProducerProtocol {
	public func addEventObserver(on queue: DispatchQueue, action: @escaping (ResourceEvent<Request>) -> Void) -> Disposable {
		let observer = DispatchObserver(queue: queue, action: action)
		let disposable = eventObserver.add(observer)
		self.disposable += disposable
		return disposable
	}
}

extension ResourceRequestReceipt: Disposable {
	public var isDisposed: Bool {
		return disposable.isDisposed
	}

	public func dispose() {
		disposable.dispose()
	}
}

extension Session {
	public func submit<T: ResourceRequestProtocol>(_ resourceRequest: T, withResourceAt localURL: URL, to peers: [MCPeerID]) throws -> ResourceRequestReceipt<T> {
		try send(resourceRequest, to: peers)

		let receipt = ResourceRequestReceipt(request: resourceRequest, peers: peers)
		let transferQueue = DispatchQueue(label: "com.junpluse.Tuka.Session.ResourceTransferQueue")

		peers.forEach { peer in
			let item = DispatchWorkItem { [mcSession] in
				let semaphore = DispatchSemaphore(value: 0)
				let progress = mcSession.sendResource(at: localURL, withName: resourceRequest.resourceName, toPeer: peer) { error in
					if let error = error {
						receipt.eventObserver.observe(.transferFailed(resourceRequest, peer, error))
					} else {
						receipt.eventObserver.observe(.transferFinished(resourceRequest, peer, localURL))
					}
					semaphore.signal()
				}
				receipt.disposable += { progress?.cancel() }
				receipt.eventObserver.observe(.transferStarted(resourceRequest, peer, progress))
				semaphore.wait()
			}
			receipt.disposable += { item.cancel() }
			transferQueue.async(execute: item)
		}

		return receipt
	}

	public func submit(resourceAt localURL: URL, to peers: [MCPeerID]) throws -> ResourceRequestReceipt<ResourceRequest> {
		let request = ResourceRequest()
		return try submit(request, withResourceAt: localURL, to: peers)
	}
}

extension Session {
	public func addResponder<T: ResourceRequestProtocol>(for resourceRequestType: T.Type, on queue: DispatchQueue, action: @escaping (_ event: ResourceEvent<T>, _ send: @escaping (_ response: T.Response) throws -> Void) -> Void) -> Disposable {
		let disposable = CompositeDisposable()

		let responderQueue = DispatchQueue(label: "com.junpluse.Tuka.Session.ResourceRequestResponderQueue")
		let responder = RequestResponder<T, MCPeerID>(queue: responderQueue) { request, peer, send in
			let sessionEventDisposable = CompositeDisposable()

			let sendAndDispose: (T.Response) throws -> Void = { response in
				try send(response)
				sessionEventDisposable.dispose()
			}

			sessionEventDisposable += self.addSessionEventObserver(on: queue) { event in
				switch event {
				case .didStartReceivingResource(let name, let from, let progress):
					guard name == request.resourceName, from == peer else { return }
					action(.transferStarted(request, peer, progress), sendAndDispose)
				case .didFinishReceivingResource(let name, let from, let localURL, let error):
					guard name == request.resourceName, from == peer else { return }
					if let error = error {
						action(.transferFailed(request, peer, error), sendAndDispose)
					} else {
						action(.transferFinished(request, peer, localURL), sendAndDispose)
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
