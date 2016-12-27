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

	fileprivate let transferDisposable = CompositeDisposable()
	fileprivate let eventObserver = CompositeObserver<Event>()

	fileprivate init(request: Request, peers: [Peer]) {
		self.request = request
		self.peers = peers
	}
}

extension ResourceRequestReceipt: ResourceEventProducerProtocol {
	public func addEventObserver(on queue: DispatchQueue, action: @escaping (ResourceEvent<Request>) -> Void) -> Disposable {
		let observer = DispatchObserver(queue: queue, action: action)
		return eventObserver.add(observer)
	}
}

extension ResourceRequestReceipt: Disposable {
	public var isDisposed: Bool {
		return transferDisposable.isDisposed
	}

	public func dispose() {
		transferDisposable.dispose()
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
						receipt.eventObserver.observe(.transferFinished(resourceRequest, peer))
					}
					semaphore.signal()
				}
				receipt.transferDisposable += { progress?.cancel() }
				receipt.eventObserver.observe(.transferStarted(resourceRequest, peer, progress))
				semaphore.wait()
			}
			receipt.transferDisposable += { item.cancel() }
			transferQueue.async(execute: item)
		}

		return receipt
	}

	public func submit(resourceAt localURL: URL, to peers: [MCPeerID]) throws -> ResourceRequestReceipt<ResourceRequest> {
		let request = ResourceRequest()
		return try submit(request, withResourceAt: localURL, to: peers)
	}
}

public final class ResourceStoreRegistration<Store: ResourceStoreProtocol> {
	public typealias Request = Store.Request
	public typealias Event = ResourceEvent<Store.Request>

	public let store: Store

	fileprivate let disposable = CompositeDisposable()
	fileprivate let eventObserver = CompositeObserver<Event>()

	fileprivate init(store: Store) {
		self.store = store
	}
}

extension ResourceStoreRegistration: ResourceEventProducerProtocol {
	public func addEventObserver(on queue: DispatchQueue, action: @escaping (ResourceEvent<Store.Request>) -> Void) -> Disposable {
		let observer = DispatchObserver(queue: queue, action: action)
		return eventObserver.add(observer)
	}
}

extension ResourceStoreRegistration: Disposable {
	public var isDisposed: Bool {
		return disposable.isDisposed
	}

	public func dispose() {
		disposable.dispose()
	}
}

extension Session {
	public func addResourceStore<T: ResourceStoreProtocol>(_ store: T) -> ResourceStoreRegistration<T> where T.Peer == MCPeerID {
		let registration = ResourceStoreRegistration(store: store)

		let responderQueue = DispatchQueue(label: "com.junpluse.Tuka.Session.ResourceRequestResponderQueue")
		let responder = RequestResponder<T.Request, MCPeerID>(queue: responderQueue) { request, peer in
			var response: T.Request.Response?
			let semaphore = DispatchSemaphore(value: 0)
			let disposable = self.addSessionEventObserver(on: store.storeQueue) { event in
				switch event {
				case .didStartReceivingResource(let name, let from, let progress):
					guard name == request.resourceName, from == peer else { return }
					registration.eventObserver.observe(.transferStarted(request, peer, progress))
				case .didFinishReceivingResource(let name, let from, let localURL, let error):
					guard name == request.resourceName, from == peer else { return }
					if let error = error {
						response = T.Request.Response(requestID: request.requestID, result: .failure)
						registration.eventObserver.observe(.transferFailed(request, peer, error))
					} else {
						do {
							try store.storeResource(at: localURL, with: request, from: peer)
							response = T.Request.Response(requestID: request.requestID, result: .success)
						} catch let error {
							print("[Tuka.Session] failed to store resource named \"\(name)\" with error: \(error)")
							response = T.Request.Response(requestID: request.requestID, result: .failure)
						}
						registration.eventObserver.observe(.transferFinished(request, peer))
					}
					semaphore.signal()
				default:
					break
				}
			}
			registration.disposable += { semaphore.signal() }
			semaphore.wait()
			disposable.dispose()
			if let response = response {
				return response
			} else {
				return T.Request.Response(requestID: request.requestID, result: .failure)
			}
		}

		registration.disposable += addResponder(responder)

		return registration
	}

	public func addResourceStore<T: ResourceRequestProtocol>(for requestType: T.Type, on queue: DispatchQueue, action: @escaping (_ fileURL: URL, _ request: T, _ peer: Peer) throws -> Void) -> ResourceStoreRegistration<ResourceStore<T, Peer>> {
		let store = ResourceStore(queue: queue, action: action)
		return addResourceStore(store)
	}
}
