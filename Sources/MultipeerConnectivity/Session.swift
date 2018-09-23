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

public final class Session {
    public typealias Peer = MCPeerID

    public let mcSession: MCSession

    public weak var mcSessionDelegate: MCSessionDelegate?

    private lazy var mcSessionDelegateProxy: MCSessionDelegateProxy = {
        return MCSessionDelegateProxy(owner: self)
    }()

    public typealias ChangeStateEvent = (peer: MCPeerID, state: MCSessionState)
    public typealias ReceiveDataEvent = (data: Data, from: MCPeerID)
    public typealias ReceiveStreamEvent = (stream: InputStream, name: String, from: MCPeerID)
    public typealias StartReceivingResourceEvent = (name: String, from: MCPeerID, progress: Progress)
    public typealias FinishReceivingResourceEvent = (name: String, from: MCPeerID, localURL: URL?, error: Error?)

    public let changeStateEvents: Signal<ChangeStateEvent, NoError>
    public let receiveDataEvents: Signal<ReceiveDataEvent, NoError>
    public let receiveStreamEvents: Signal<ReceiveStreamEvent, NoError>
    public let startReceivingResourceEvents: Signal<StartReceivingResourceEvent, NoError>
    public let finishReceivingResourceEvents: Signal<FinishReceivingResourceEvent, NoError>

    private let changeStateEventsObserver: Signal<ChangeStateEvent, NoError>.Observer
    private let receiveDataEventsObserver: Signal<ReceiveDataEvent, NoError>.Observer
    private let receiveStreamEventsObserver: Signal<ReceiveStreamEvent, NoError>.Observer
    private let startReceivingResourceEventsObserver: Signal<StartReceivingResourceEvent, NoError>.Observer
    private let finishReceivingResourceEventsObserver: Signal<FinishReceivingResourceEvent, NoError>.Observer

    public var myPeer: Peer {
        return mcSession.myPeerID
    }

    public let connectedPeers: Property<Set<Peer>>

    private var peerInvitationManager: PeerInvitationManager?

    private let messageEncoder = PropertyListEncoder()
    private let messageDecoder = PropertyListDecoder()

    public init(mcSession: MCSession) {
        self.mcSession = mcSession

        (changeStateEvents, changeStateEventsObserver) = Signal.pipe()
        (receiveDataEvents, receiveDataEventsObserver) = Signal.pipe()
        (receiveStreamEvents, receiveStreamEventsObserver) = Signal.pipe()
        (startReceivingResourceEvents, startReceivingResourceEventsObserver) = Signal.pipe()
        (finishReceivingResourceEvents, finishReceivingResourceEventsObserver) = Signal.pipe()

        let connectedPeersUpdates = changeStateEvents.map { _ in Set(mcSession.connectedPeers) }
        connectedPeers = Property(initial: Set(mcSession.connectedPeers), then: connectedPeersUpdates).skipRepeats()

        mcSession.delegate = mcSessionDelegateProxy
    }

    public convenience init() {
        self.init(mcSession: MCSession(peer: MCPeerID.Tuka.defaultPeer))
    }
}

extension Session {
    private final class MCSessionDelegateProxy: NSObject, MCSessionDelegate {
        unowned let owner: Session

        init(owner: Session) {
            self.owner = owner
        }

        @objc func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
            owner.mcSessionDelegate?.session(session, peer: peerID, didChange: state)
            owner.changeStateEventsObserver.send(value: (peerID, state))
        }

        @objc func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
            owner.mcSessionDelegate?.session(session, didReceive: data, fromPeer: peerID)
            owner.receiveDataEventsObserver.send(value: (data, peerID))
        }

        @objc func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
            owner.mcSessionDelegate?.session(session, didReceive: stream, withName: streamName, fromPeer: peerID)
            owner.receiveStreamEventsObserver.send(value: (stream, streamName, peerID))
        }

        @objc func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
            owner.mcSessionDelegate?.session(session, didStartReceivingResourceWithName: resourceName, fromPeer: peerID, with: progress)
            owner.startReceivingResourceEventsObserver.send(value: (resourceName, peerID, progress))
        }

        @objc func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
            owner.mcSessionDelegate?.session(session, didFinishReceivingResourceWithName: resourceName, fromPeer: peerID, at: localURL, withError: error)
            owner.finishReceivingResourceEventsObserver.send(value: (resourceName, peerID, localURL, error))
        }

        @objc func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
            if owner.mcSessionDelegate?.session?(session, didReceiveCertificate: certificate, fromPeer: peerID, certificateHandler: certificateHandler) == nil {
                certificateHandler(true)
            }
        }
    }
}

extension Session {
    public func send(_ data: Data, to peers: Set<Peer>, mode: MCSessionSendDataMode) throws {
        try mcSession.send(data, toPeers: Array(peers), with: mode)
    }
}

extension Session: DataSender {
    public func send(_ data: Data, to peers: Set<Peer>) throws {
        try send(data, to: peers, mode: .reliable)
    }
}

extension Session: DataReceiver {
    public var incomingData: Signal<(Data, Peer), NoError> {
        return receiveDataEvents.map { $0 }
    }
}

extension Session: MessageEncoder {
    public func encodeMessage<Message: Tuka.Message>(_ message: Message) throws -> Data {
        return try messageEncoder.encode(message)
    }
}

extension Session: MessageDecoder {
    public func decodeMessage<Message: Tuka.Message>(of type: Message.Type, from data: Data) throws -> Message {
        return try messageDecoder.decode(type, from: data)
    }
}

extension Session: MessageSender {}

extension Session: MessageReceiver {}

extension Session {
    public func broadcast(_ data: Data, mode: MCSessionSendDataMode = .reliable) throws {
        let peers = connectedPeers.value

        guard !peers.isEmpty else {
            return
        }

        try send(data, to: peers, mode: mode)
    }

    public func broadcast<Message: Tuka.Message>(_ message: Message, mode: MCSessionSendDataMode = .reliable) throws {
        let data = try encodeMessage(message)
        try broadcast(data, mode: mode)
    }
}

extension Session {
    public func startAutomaticPeerInvitations(withServiceType serviceType: String) {
        precondition(peerInvitationManager == nil)

        peerInvitationManager = PeerInvitationManager(session: mcSession, serviceType: serviceType)
        peerInvitationManager?.start()
    }

    public func stopAutomaticPeerInvitations() {
        peerInvitationManager?.stop()
        peerInvitationManager = nil
    }
}
