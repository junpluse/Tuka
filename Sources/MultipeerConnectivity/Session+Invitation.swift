//
//  Session+Invitation.swift
//  Tuka
//
//  Created by Jun Tanaka on 2018/09/24.
//  Copyright © 2018 Jun Tanaka. All rights reserved.
//

import MultipeerConnectivity
import ReactiveSwift

extension Session {
    public enum PeerInvitationError: Error {
        case advertisingNotStarted(Error)
        case browsingNotStarted(Error)
    }

    public func automaticPeerInvitations(withServiceType serviceType: String) -> SignalProducer<Peer, PeerInvitationError> {
        let connectedPeers = changeStateEvents
            .filter { $0.state == .connected }
            .map { $0.peer }

        return SignalProducer { [mcSession] observer, lifetime in
            let manager = PeerInvitationManager(session: mcSession, serviceType: serviceType)
            let errorDelegateProxy = PeerInvitationManagerErrorDelegateProxy()

            manager.errorDelegate = errorDelegateProxy

            lifetime += connectedPeers.observeValues { observer.send(value: $0) }
            lifetime += errorDelegateProxy.errors.observeFailed { observer.send(error: $0) }

            lifetime.observeEnded { _ = errorDelegateProxy }
            lifetime.observeEnded { manager.stop() }

            manager.start()
        }
    }

    private final class PeerInvitationManagerErrorDelegateProxy: NSObject, PeerInvitationManagerErrorDelegate {
        let errors: Signal<Never, PeerInvitationError>

        private let observer: Signal<Never, PeerInvitationError>.Observer

        override init() {
            (errors, observer) = Signal.pipe()
        }

        func peerInvitationManager(_ manager: PeerInvitationManager, didNotStartAdvertisingPeer error: Error) {
            observer.send(error: .advertisingNotStarted(error))
        }

        func peerInvitationManager(_ manager: PeerInvitationManager, didNotStartBrowsingPeer error: Error) {
            observer.send(error: .browsingNotStarted(error))
        }
    }
}
