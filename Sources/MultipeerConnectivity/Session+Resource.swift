//
//  Session+Resource.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/18.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public enum ResourceEvent<Request: ResourceRequestProtocol> {
	case transferStarted(Request, Session.Peer, Progress?)
	case transferFinished(Request, Session.Peer)
	case transferFailed(Request, Session.Peer, Error)
}

public final class ResourceRequestReceipt<Request: ResourceRequestProtocol>: RequestReceiptProtocol, Disposable {
	public typealias Peer = Session.Peer

	public let request: Request
	public let peers: [Peer]

	private let transferDisposable: Disposable

	init(request: Request, peers: [Peer], transferDisposable: Disposable) {
		self.request = request
		self.peers = peers
		self.transferDisposable = transferDisposable
	}

	public var isDisposed: Bool {
		return transferDisposable.isDisposed
	}

	public func dispose() {
		transferDisposable.dispose()
	}
}

extension Session {
	public func submit<T: ResourceRequestProtocol>(_ resourceRequest: T, withResourceAt localURL: URL, to peers: [MCPeerID], eventQueue: DispatchQueue? = nil, eventHandler: @escaping (ResourceEvent<T>) -> Void = { _ in }) throws -> ResourceRequestReceipt<T> {
		let eventObserver = DispatchObserver(queue: eventQueue, action: eventHandler)

		try send(resourceRequest, to: peers)

		let transferQueue = DispatchQueue(label: "com.junpluse.Tuka.Session.ResourceTransferQueue")
		let transferDisposable = CompositeDisposable()

		peers.forEach { peer in
			let item = DispatchWorkItem { [mcSession] in
				let semaphore = DispatchSemaphore(value: 0)
				let progress = mcSession.sendResource(at: localURL, withName: resourceRequest.requestID, toPeer: peer) { error in
					if let error = error {
						eventObserver.observe(.transferFailed(resourceRequest, peer, error))
					} else {
						eventObserver.observe(.transferFinished(resourceRequest, peer))
					}
					semaphore.signal()
				}
				transferDisposable += { progress?.cancel() }
				eventObserver.observe(.transferStarted(resourceRequest, peer, progress))
				semaphore.wait()
			}
			transferDisposable += { item.cancel() }
			transferQueue.async(execute: item)
		}

		return ResourceRequestReceipt(request: resourceRequest, peers: peers, transferDisposable: transferDisposable)
	}

	public func submitResourceRequest(withName resourceName: String, at localURL: URL, to peers: [MCPeerID], eventHandler: @escaping (ResourceEvent<ResourceRequest>) -> Void = { _ in }) throws -> ResourceRequestReceipt<ResourceRequest> {
		let request = ResourceRequest(resourceName: resourceName, preferredFilename: localURL.lastPathComponent)
		return try submit(request, withResourceAt: localURL, to: peers, eventHandler: eventHandler)
	}
}

extension Session {
	public func addResponder<T: ResourceStoreProtocol>(forResourceRequestTo store: T, eventQueue: DispatchQueue? = nil, eventHandler: @escaping (ResourceEvent<T.Request>) -> Void = { _ in }) -> Disposable where T.Peer == MCPeerID {
		let eventObserver = DispatchObserver(queue: eventQueue, action: eventHandler)

		let responderQueue = DispatchQueue(label: "com.junpluse.Tuka.Session.ResourceRequestResponderQueue")
		let responder = RequestResponder<T.Request, MCPeerID>(queue: responderQueue) { request, peer in
			var response: T.Request.Response!
			let semaphore = DispatchSemaphore(value: 0)
			let disposable = self.addSessionEventObserver(on: store.storeQueue) { event in
				switch event {
				case .didStartReceivingResource(let name, let from, let progress):
					guard name == request.requestID, from == peer else { return }
					eventObserver.observe(.transferStarted(request, peer, progress))
				case .didFinishReceivingResource(let name, let from, let localURL, let error):
					guard name == request.requestID, from == peer else { return }
					if let error = error {
						response = T.Request.Response(requestID: request.requestID, result: .failure)
						eventObserver.observe(.transferFailed(request, peer, error))
					} else {
						do {
							try store.storeResource(at: localURL, with: request, from: peer)
							response = T.Request.Response(requestID: request.requestID, result: .success)
						} catch let error {
							print("[Tuka.Session] failed to store resource named \"\(name)\" with error: \(error)")
							response = T.Request.Response(requestID: request.requestID, result: .failure)
						}
						eventObserver.observe(.transferFinished(request, peer))
					}
					semaphore.signal()
				default:
					break
				}
			}
			semaphore.wait()
			disposable.dispose()
			return response
		}

		return addResponder(responder)
	}
}
