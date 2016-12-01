//
//  Session.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

public final class Session: NSObject, MessageSenderProtocol, MessageReceiverProtocol, MCSessionDelegate {
	public typealias Peer = MCPeerID

	public let mcSession: MCSession

	public weak var mcSessionDelegate: MCSessionDelegate?

	public enum Event {
		case peerDidChangeState(MCPeerID, MCSessionState)
		case didReceiveData(Data, from: MCPeerID)
		case didReceiveStream(InputStream, name: String, from: MCPeerID)
		case didStartReceivingResource(name: String, from: MCPeerID, progress: Progress)
		case didFinishReceivingResource(name: String, from: MCPeerID, localURL: URL, error: Error?)
	}

	private let _sessionEventObserver = CompositeObserver<Event>()

	public init(mcSession: MCSession) {
		self.mcSession = mcSession
		super.init()
		mcSession.delegate = self
	}

	public override convenience init() {
		self.init(mcSession: MCSession(peer: MCPeerID.Tuka.defaultPeer))
	}

	public func observeSessionEvent(on queue: DispatchQueue? = nil, handler: @escaping (Event) -> Void) -> Disposable {
		let observer = DispatchObserver(queue: queue, action: handler)
		return _sessionEventObserver.add(observer)
	}

	public func send(_ data: Data, of message: MessageProtocol, to peers: [MCPeerID], with mode: MCSessionSendDataMode) throws {
		try mcSession.send(data, toPeers: peers, with: mode)
	}

	public func send<T: MessageProtocol>(_ message: T, to peers: [MCPeerID], with mode: MCSessionSendDataMode) throws {
		let data = Archiver().archive(message)
		try send(data, of: message, to: peers, with: mode)
	}

	// MARK: MessageSenderProtocol

	public func send(_ data: Data, of message: MessageProtocol, to peers: [MCPeerID]) throws {
		let mode = (message as? SessionMessageProtocol)?.preferredSendDataMode ?? .reliable
		try send(data, of: message, to: peers, with: mode)
	}

	// MARK: MessageReceiverProtocol

	public func observeReceivedData(on queue: DispatchQueue, handler: @escaping (Data, MCPeerID) -> Void) -> Disposable {
		let observer = DispatchObserver(queue: queue, action: handler)
		return _sessionEventObserver.add { event in
			switch event {
			case .didReceiveData(let data, let peer):
				observer.observe(data, peer)
			default:
				break
			}
		}
	}

	// MARK: MCSessionDelegate

	@objc public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		mcSessionDelegate?.session(session, peer: peerID, didChange: state)
		_sessionEventObserver.observe(.peerDidChangeState(peerID, state))
	}

	@objc public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		mcSessionDelegate?.session(session, didReceive: data, fromPeer: peerID)
		_sessionEventObserver.observe(.didReceiveData(data, from: peerID))
	}

	@objc public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		mcSessionDelegate?.session(session, didReceive: stream, withName: streamName, fromPeer: peerID)
		_sessionEventObserver.observe(.didReceiveStream(stream, name: streamName, from: peerID))
	}

	@objc public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		mcSessionDelegate?.session(session, didStartReceivingResourceWithName: resourceName, fromPeer: peerID, with: progress)
		_sessionEventObserver.observe(.didStartReceivingResource(name: resourceName, from: peerID, progress: progress))
	}

	@objc public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
		mcSessionDelegate?.session(session, didFinishReceivingResourceWithName: resourceName, fromPeer: peerID, at: localURL, withError: error)
		_sessionEventObserver.observe(.didFinishReceivingResource(name: resourceName, from: peerID, localURL: localURL, error: error))
	}

	@objc public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
		if mcSessionDelegate?.session?(session, didReceiveCertificate: certificate, fromPeer: peerID, certificateHandler: certificateHandler) == nil {
			certificateHandler(true)
		}
	}
}
