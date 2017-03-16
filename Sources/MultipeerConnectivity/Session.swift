//
//  Session.swift
//  Tuka
//
//  Created by Jun Tanaka on 2016/11/17.
//  Copyright © 2016 Jun Tanaka. All rights reserved.
//

import MultipeerConnectivity
import ReactiveSwift
import Result

public final class Session: NSObject {
	public typealias Peer = MCPeerID

	public let mcSession: MCSession

	public weak var mcSessionDelegate: MCSessionDelegate?

	public typealias ChangeStateEvent = (peer: MCPeerID, state: MCSessionState)
	public typealias ReceiveDataEvent = (data: Data, from: MCPeerID)
	public typealias ReceiveStreamEvent = (stream: InputStream, name: String, from: MCPeerID)
	public typealias StartReceivingResourceEvent = (name: String, from: MCPeerID, progress: Progress)
	public typealias FinishReceivingResourceEvent = (name: String, from: MCPeerID, localURL: URL, error: Error?)

	public let changeStateEvents: Signal<ChangeStateEvent, NoError>
	public let receiveDataEvents: Signal<ReceiveDataEvent, NoError>
	public let receiveStreamEvents: Signal<ReceiveStreamEvent, NoError>
	public let startReceivingResourceEvents: Signal<StartReceivingResourceEvent, NoError>
	public let finishReceivingResourceEvents: Signal<FinishReceivingResourceEvent, NoError>

	fileprivate let changeStateEventsObserver: ReactiveSwift.Observer<ChangeStateEvent, NoError>
	fileprivate let receiveDataEventsObserver: ReactiveSwift.Observer<ReceiveDataEvent, NoError>
	fileprivate let receiveStreamEventsObserver: ReactiveSwift.Observer<ReceiveStreamEvent, NoError>
	fileprivate let startReceivingResourceEventsObserver: ReactiveSwift.Observer<StartReceivingResourceEvent, NoError>
	fileprivate let finishReceivingResourceEventsObserver: ReactiveSwift.Observer<FinishReceivingResourceEvent, NoError>

	public init(mcSession: MCSession) {
		self.mcSession = mcSession

		(changeStateEvents, changeStateEventsObserver) = Signal.pipe()
		(receiveDataEvents, receiveDataEventsObserver) = Signal.pipe()
		(receiveStreamEvents, receiveStreamEventsObserver) = Signal.pipe()
		(startReceivingResourceEvents, startReceivingResourceEventsObserver) = Signal.pipe()
		(finishReceivingResourceEvents, finishReceivingResourceEventsObserver) = Signal.pipe()

		super.init()

		mcSession.delegate = self
	}

	public override convenience init() {
		self.init(mcSession: MCSession(peer: MCPeerID.Tuka.defaultPeer))
	}

	public func send(_ data: Data, to peers: [Peer], with mode: MCSessionSendDataMode) throws {
		try mcSession.send(data, toPeers: peers, with: mode)
	}
}

extension Session: MCSessionDelegate {
	@objc public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		mcSessionDelegate?.session(session, peer: peerID, didChange: state)
		changeStateEventsObserver.send(value: (peerID, state))
	}

	@objc public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		mcSessionDelegate?.session(session, didReceive: data, fromPeer: peerID)
		receiveDataEventsObserver.send(value: (data, peerID))
	}

	@objc public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		mcSessionDelegate?.session(session, didReceive: stream, withName: streamName, fromPeer: peerID)
		receiveStreamEventsObserver.send(value: (stream, streamName, peerID))
	}

	@objc public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		mcSessionDelegate?.session(session, didStartReceivingResourceWithName: resourceName, fromPeer: peerID, with: progress)
		startReceivingResourceEventsObserver.send(value: (resourceName, peerID, progress))
	}

	@objc public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
		mcSessionDelegate?.session(session, didFinishReceivingResourceWithName: resourceName, fromPeer: peerID, at: localURL, withError: error)
		finishReceivingResourceEventsObserver.send(value: (resourceName, peerID, localURL, error))
	}

	@objc public func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
		if mcSessionDelegate?.session?(session, didReceiveCertificate: certificate, fromPeer: peerID, certificateHandler: certificateHandler) == nil {
			certificateHandler(true)
		}
	}
}

extension Session: DataSender {
	public func send(_ data: Data, to peers: [Peer]) throws {
		try send(data, to: peers, with: .reliable)
	}
}

extension Session: MessageSender {
	public func send<Message: Tuka.Message>(_ message: Message, to peers: [MCPeerID]) throws {
		let context = MessageSerializationContext()
		let data = try message.serializedData(with: context)
		let mode = (message as? SessionMessage)?.preferredSendDataMode ?? .reliable
		try send(data, to: peers, with: mode)
	}
}

extension Session: DataReceiver {
	public var incomingData: Signal<(Data, Peer), NoError> {
		return receiveDataEvents.map { $0 }
	}
}

extension Session: MessageReceiver {}
