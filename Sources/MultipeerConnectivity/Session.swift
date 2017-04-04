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

    fileprivate let changeStateEventsObserver: Observer<ChangeStateEvent, NoError>
    fileprivate let receiveDataEventsObserver: Observer<ReceiveDataEvent, NoError>
    fileprivate let receiveStreamEventsObserver: Observer<ReceiveStreamEvent, NoError>
    fileprivate let startReceivingResourceEventsObserver: Observer<StartReceivingResourceEvent, NoError>
    fileprivate let finishReceivingResourceEventsObserver: Observer<FinishReceivingResourceEvent, NoError>

    public var myPeer: Peer {
        return mcSession.myPeerID
    }

    public let connectedPeers: Property<Set<Peer>>

    public init(mcSession: MCSession) {
        self.mcSession = mcSession

        (changeStateEvents, changeStateEventsObserver) = Signal.pipe()
        (receiveDataEvents, receiveDataEventsObserver) = Signal.pipe()
        (receiveStreamEvents, receiveStreamEventsObserver) = Signal.pipe()
        (startReceivingResourceEvents, startReceivingResourceEventsObserver) = Signal.pipe()
        (finishReceivingResourceEvents, finishReceivingResourceEventsObserver) = Signal.pipe()

        let connectedPeersUpdates = changeStateEvents.map { _ in Set(mcSession.connectedPeers) }
        connectedPeers = Property(initial: Set(mcSession.connectedPeers), then: connectedPeersUpdates).skipRepeats()

        super.init()

        mcSession.delegate = self
    }

    public override convenience init() {
        self.init(mcSession: MCSession(peer: MCPeerID.Tuka.defaultPeer))
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

extension Session {
    public func send(_ data: Data, to peers: Set<Peer>, mode: MCSessionSendDataMode) throws {
        try mcSession.send(data, toPeers: Array(peers), with: mode)
    }

    public func send(name: MessageName, withData data: Data? = nil, to peers: Set<Peer>, mode: MCSessionSendDataMode) throws {
        let packet = MessagePacket(name: name.rawValue, data: data)
        let packetData = NSKeyedArchiver.archivedData(withRootObject: packet)
        try send(packetData, to: peers, mode: mode)
    }

    public func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>, mode: MCSessionSendDataMode) throws {
        let name = Message.messageName
        let data = try message.serializedData()
        try send(name: name, withData: data, to: peers, mode: mode)
    }
}

extension Session {
    public func send(_ data: Data, mode: MCSessionSendDataMode = .reliable) throws {
        try send(data, to: connectedPeers.value, mode: mode)
    }

    public func send(name: MessageName, withData data: Data? = nil, mode: MCSessionSendDataMode = .reliable) throws {
        try send(name: name, to: connectedPeers.value, mode: mode)
    }

    public func send<Message: Tuka.Message>(_ message: Message, mode: MCSessionSendDataMode = .reliable) throws {
        try send(message, to: connectedPeers.value, mode: mode)
    }
}

extension Session: DataSender {
    public func send(_ data: Data, to peers: Set<Peer>) throws {
        try send(data, to: peers, mode: .reliable)
    }
}

extension Session: MessageSender {
    public func send(name: MessageName, withData data: Data? = nil, to peers: Set<Peer>) throws {
        try send(name: name, to: peers, mode: .reliable)
    }

    public func send<Message: Tuka.Message>(_ message: Message, to peers: Set<Peer>) throws {
        try send(message, to: peers, mode: .reliable)
    }
}

extension Session: DataReceiver {
    public var incomingData: Signal<(Data, Peer), NoError> {
        return receiveDataEvents.map { $0 }
    }
}

extension Session: MessageReceiver {}
